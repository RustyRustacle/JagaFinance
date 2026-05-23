import { Router } from "express";
import { z } from "zod";
import { prisma } from "@jagafinance/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";
import { validate } from "../middleware/validate";
import { enqueueExport } from "../lib/queue";
import { ExportService } from "../services/export";

export const exportRouter = Router();

const createExportSchema = z.object({
  format: z.enum(["CSV", "XLSX", "PDF"]).default("CSV"),
  export_type: z.enum(["expenses", "receipts", "budget_report", "tax_summary"]),
  filters: z.object({
    date_from: z.string().optional(),
    date_to: z.string().optional(),
    category_id: z.string().uuid().optional(),
    status: z.string().optional(),
    accounting_format: z.enum(["standard", "jurnal", "accurate"]).optional(),
  }).optional(),
});

exportRouter.use(authMiddleware);

exportRouter.post(
  "/",
  validate(createExportSchema),
  async (req: AuthRequest, res) => {
    const { format, export_type, filters } = req.body;

    const exportJob = await prisma.exportJob.create({
      data: {
        tenantId: req.user!.tenantId,
        requestedBy: req.user!.id,
        format,
        exportType: export_type,
        filters: filters ?? {},
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    await enqueueExport(exportJob.id);

    res.status(201).json({ success: true, data: exportJob });
  }
);

exportRouter.get("/", async (req: AuthRequest, res) => {
  const jobs = await prisma.exportJob.findMany({
    where: { tenantId: req.user!.tenantId },
    orderBy: { createdAt: "desc" },
  });

  res.json({ success: true, data: jobs });
});

exportRouter.get("/:id", async (req: AuthRequest, res) => {
  const job = await prisma.exportJob.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  if (!job) {
    throw new AppError(404, "NOT_FOUND", "Export job not found");
  }

  res.json({ success: true, data: job });
});

exportRouter.get("/:id/download", async (req: AuthRequest, res) => {
  const job = await prisma.exportJob.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  if (!job) {
    throw new AppError(404, "NOT_FOUND", "Export not found");
  }

  if (job.status !== "COMPLETED" || !job.fileUrl) {
    throw new AppError(400, "NOT_READY", "Export is not ready yet");
  }

  const { supabase } = await import("../lib/supabase");
  const { data, error } = await supabase.storage
    .from("exports")
    .download(job.fileUrl);

  if (error) {
    throw new AppError(500, "DOWNLOAD_ERROR", error.message);
  }

  const contentType = job.format === "PDF"
    ? "application/pdf"
    : job.format === "XLSX"
      ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      : "text/csv";

  const ext = job.format.toLowerCase();
  res.setHeader("Content-Type", contentType);
  res.setHeader("Content-Disposition", `attachment; filename=export.${ext}`);

  const buffer = Buffer.from(await (data as Blob).arrayBuffer());
  res.send(buffer);
});

exportRouter.post("/quick-export", authMiddleware, async (req: AuthRequest, res) => {
  const { format = "CSV", export_type = "expenses", filters = {} } = req.body as Record<string, unknown>;

  const exportSvc = new ExportService();
  const typedFilters = filters as Record<string, string>;

  let content: Buffer | string;
  let contentType: string;
  let fileName: string;

  if (export_type === "expenses") {
    if (typedFilters.accounting_format === "jurnal") {
      content = await exportSvc.exportForJurnal(req.user!.tenantId, typedFilters);
      contentType = "text/tab-separated-values";
      fileName = "expenses-jurnal.tsv";
    } else if (typedFilters.accounting_format === "accurate") {
      content = await exportSvc.exportForAccurate(req.user!.tenantId, typedFilters);
      contentType = "text/csv";
      fileName = "expenses-accurate.csv";
    } else if (format === "XLSX") {
      content = await exportSvc.exportExpensesXLSX(req.user!.tenantId, typedFilters);
      contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      fileName = "expenses.xlsx";
    } else if (format === "PDF") {
      content = await exportSvc.exportExpensesPDF(req.user!.tenantId, typedFilters);
      contentType = "application/pdf";
      fileName = "expenses.pdf";
    } else {
      content = await exportSvc.exportExpensesCSV(req.user!.tenantId, typedFilters);
      contentType = "text/csv";
      fileName = "expenses.csv";
    }
  } else {
    throw new AppError(400, "NOT_IMPLEMENTED", "Export type not supported");
  }

  const buffer = Buffer.isBuffer(content) ? content : Buffer.from(content as string);

  res.setHeader("Content-Type", contentType);
  res.setHeader("Content-Disposition", `attachment; filename=${fileName}`);
  res.send(buffer);
});
