import { Worker, Queue, Job } from "bullmq";
import Redis from "ioredis";
import { prisma } from "@jagafinance/db";
import { supabase } from "../lib/supabase";
import { OCRService } from "../services/ocr";
import { EmailService } from "../services/email";

const ocrService = new OCRService();
const emailService = new EmailService();

export async function startWorkers() {
  const connection = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
    maxRetriesPerRequest: null,
  });

  const ocrWorker = new Worker(
    "ocr-processing",
    async (job: Job) => {
      const { receiptId } = job.data;
      await processOCR(receiptId);
    },
    {
      connection,
      concurrency: 3,
    }
  );

  const alertWorker = new Worker(
    "budget-alerts",
    async (job: Job) => {
      const { budgetId } = job.data;
      await checkBudgetAlert(budgetId);
    },
    {
      connection,
      concurrency: 5,
    }
  );

  const exportWorker = new Worker(
    "export-processing",
    async (job: Job) => {
      const { exportId } = job.data;
      await processExport(exportId);
    },
    {
      connection,
      concurrency: 2,
    }
  );

  setupWorkerEvents(ocrWorker, "OCR");
  setupWorkerEvents(alertWorker, "Alert");
  setupWorkerEvents(exportWorker, "Export");

  console.log("Queue workers started: OCR, Budget Alerts, Exports");
}

function setupWorkerEvents(worker: Worker, name: string) {
  worker.on("completed", (job) => {
    console.log(`[${name}] Job ${job.id} completed`);
  });

  worker.on("failed", (job, err) => {
    console.error(`[${name}] Job ${job?.id} failed:`, err.message);
  });
}

async function processOCR(receiptId: string) {
  console.log(`[OCR] Processing receipt: ${receiptId}`);

  try {
    await prisma.receipt.update({
      where: { id: receiptId },
      data: { status: "PROCESSING" },
    });

    const receipt = await prisma.receipt.findUnique({
      where: { id: receiptId },
    });

    if (!receipt) {
      throw new Error(`Receipt ${receiptId} not found`);
    }

    const fileName = receipt.fileUrl.split("/").slice(-2).join("/");

    const { data: fileData, error } = await supabase.storage
      .from("receipts")
      .download(fileName);

    if (error || !fileData) {
      throw new Error(`Failed to download receipt file: ${error.message}`);
    }

    const buffer = Buffer.from(await fileData.arrayBuffer());
    const ocrResult = await ocrService.processImage(buffer);

    await prisma.receiptData.create({
      data: {
        receiptId,
        merchantName: ocrResult.merchantName,
        merchantAddress: ocrResult.merchantAddress,
        merchantPhone: ocrResult.merchantPhone,
        receiptNumber: ocrResult.receiptNumber,
        transactionDate: ocrResult.transactionDate,
        subtotal: ocrResult.subtotal,
        taxAmount: ocrResult.taxAmount,
        taxRate: ocrResult.taxRate,
        discountAmount: ocrResult.discountAmount,
        totalAmount: ocrResult.totalAmount,
        currency: ocrResult.currency,
        paymentMethod: ocrResult.paymentMethod,
        lineItems: ocrResult.lineItems,
      },
    });

    await prisma.receipt.update({
      where: { id: receiptId },
      data: {
        status: "COMPLETED",
        ocrConfidence: ocrResult.confidence,
        ocrRawResponse: JSON.parse(JSON.stringify({ text: ocrResult.rawText })),
        processedAt: new Date(),
      },
    });

    console.log(`[OCR] Completed: ${receiptId} - confidence: ${ocrResult.confidence.toFixed(2)}`);
  } catch (error) {
    console.error(`[OCR] Failed: ${receiptId} -`, error instanceof Error ? error.message : error);

    await prisma.receipt.update({
      where: { id: receiptId },
      data: {
        status: "FAILED",
        errorMessage: error instanceof Error ? error.message : "Unknown OCR error",
      },
    }).catch((e) => {
      console.error(`[OCR] Failed to update receipt status:`, e.message);
    });

    throw error;
  }
}

async function checkBudgetAlert(budgetId: string) {
  const budget = await prisma.budget.findUnique({
    where: { id: budgetId },
    include: {
      category: true,
      tenant: true,
    },
  });

  if (!budget || !budget.isActive) return;

  const spent = await prisma.expense.aggregate({
    where: {
      tenantId: budget.tenantId,
      categoryId: budget.categoryId,
      expenseDate: {
        gte: budget.startDate,
        lte: budget.endDate,
      },
      status: { in: ["CONFIRMED", "RECONCILED"] },
    },
    _sum: { amount: true },
  });

  const currentAmount = spent._sum.amount?.toNumber() ?? 0;
  const budgetAmount = budget.amount.toNumber();
  const percentage = (currentAmount / budgetAmount) * 100;

  const threshold = budget.alertThreshold.toNumber();

  if (percentage >= threshold) {
    const members = await prisma.tenantMember.findMany({
      where: {
        tenantId: budget.tenantId,
        role: { in: ["ADMIN", "FINANCE"] },
        status: "ACCEPTED",
      },
      include: { user: true },
    });

    for (const member of members) {
      if (!member.user?.email) continue;

      await prisma.budgetAlert.create({
        data: {
          tenantId: budget.tenantId,
          budgetId: budget.id,
          currentAmount,
          budgetAmount,
          percentageUsed: Math.round(percentage * 100) / 100,
          channel: "EMAIL",
          recipientEmail: member.user.email,
        },
      });

      await emailService.sendBudgetAlert({
        recipient: member.user.email,
        tenantName: budget.tenant.name,
        categoryName: budget.category.name,
        currentAmount,
        budgetAmount,
        percentage,
        period: budget.period,
      });

      console.log(`[Alert] Sent to ${member.user.email}: ${budget.category.name} at ${percentage.toFixed(1)}%`);
    }
  }
}

async function processExport(exportId: string) {
  console.log(`[Export] Processing: ${exportId}`);

  const job = await prisma.exportJob.findUnique({
    where: { id: exportId },
    include: { requester: { select: { email: true } } },
  });

  if (!job) return;

  await prisma.exportJob.update({
    where: { id: exportId },
    data: { status: "PROCESSING" },
  });

  const filters = job.filters as Record<string, string>;
  const { ExportService } = await import("../services/export");
  const exportSvc = new ExportService();

  let content: Buffer | string;
  let fileName: string;

  if (job.exportType === "expenses") {
    if (filters.accounting_format === "jurnal") {
      content = await exportSvc.exportForJurnal(job.tenantId, filters);
      fileName = `expenses-jurnal-${Date.now()}.tsv`;
    } else if (filters.accounting_format === "accurate") {
      content = await exportSvc.exportForAccurate(job.tenantId, filters);
      fileName = `expenses-accurate-${Date.now()}.csv`;
    } else if (job.format === "XLSX") {
      content = await exportSvc.exportExpensesXLSX(job.tenantId, filters);
      fileName = `expenses-${Date.now()}.xlsx`;
    } else if (job.format === "PDF") {
      content = await exportSvc.exportExpensesPDF(job.tenantId, filters);
      fileName = `expenses-${Date.now()}.pdf`;
    } else {
      content = await exportSvc.exportExpensesCSV(job.tenantId, filters);
      fileName = `expenses-${Date.now()}.csv`;
    }
  } else {
    throw new Error(`Export type not implemented: ${job.exportType}`);
  }

  const { data, error } = await supabase.storage
    .from("exports")
    .upload(`${job.tenantId}/${fileName}`, content, {
      contentType: job.format === "PDF"
        ? "application/pdf"
        : job.format === "XLSX"
          ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          : "text/csv",
    });

  if (error) {
    await prisma.exportJob.update({
      where: { id: exportId },
      data: {
        status: "FAILED",
        errorMessage: `Storage upload failed: ${error.message}`,
      },
    });
    return;
  }

  await prisma.exportJob.update({
    where: { id: exportId },
    data: {
      status: "COMPLETED",
      fileUrl: data.path,
      completedAt: new Date(),
    },
  });

  if (job.requester?.email) {
    await emailService.sendExportReady(
      job.requester.email,
      job.exportType,
      `/api/v1/exports/${exportId}/download`
    );
  }

  console.log(`[Export] Completed: ${exportId}`);
}
