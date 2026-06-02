import ExcelJS from "exceljs";
import PDFDocument from "pdfkit";
import { prisma } from "@jagafinance/db";
import * as fs from "fs";
import * as path from "path";

export interface ExportFilters {
  date_from?: string;
  date_to?: string;
  category_id?: string;
  status?: string;
  accounting_format?: "standard" | "jurnal" | "accurate";
}

export class ExportService {
  async exportExpensesXLSX(
    tenantId: string,
    filters: ExportFilters
  ): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = "JagaFinance";
    workbook.created = new Date();

    const worksheet = workbook.addWorksheet("Expenses", {
      properties: { defaultRowHeight: 20 },
    });

    worksheet.columns = [
      { header: "Date", key: "date", width: 14 },
      { header: "Receipt #", key: "receipt", width: 16 },
      { header: "Merchant", key: "merchant", width: 25 },
      { header: "Category", key: "category", width: 20 },
      { header: "Description", key: "description", width: 30 },
      { header: "Amount", key: "amount", width: 18 },
      { header: "Tax", key: "tax", width: 12 },
      { header: "Payment", key: "payment", width: 12 },
      { header: "Status", key: "status", width: 14 },
      { header: "Tags", key: "tags", width: 20 },
    ];

    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: "FFFFFFFF" } };
    headerRow.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FF2563EB" },
    };
    headerRow.alignment = { vertical: "middle" };

    const expenses = await this.getExpenses(tenantId, filters);
    let totalAmount = 0;

    for (const exp of expenses) {
      const row = worksheet.addRow({
        date: new Date(exp.expenseDate).toLocaleDateString("id-ID"),
        receipt: exp.receipt?.receiptData?.receiptNumber || "-",
        merchant: exp.receipt?.receiptData?.merchantName || "-",
        category: (exp.category as { name: string })?.name || "-",
        description: exp.description || "",
        amount: parseFloat(exp.amount.toString()),
        tax: exp.receipt?.receiptData?.taxAmount
          ? parseFloat(exp.receipt.receiptData.taxAmount.toString())
          : 0,
        payment: exp.paymentMethod || "-",
        status: exp.status,
        tags: (exp.tags as string[]).join(", "),
      });

      row.alignment = { vertical: "middle" };
      row.getCell("amount").numFmt = '#,##0';
      row.getCell("tax").numFmt = '#,##0';
      totalAmount += parseFloat(exp.amount.toString());
    }

    const totalRow = worksheet.addRow({
      description: "TOTAL",
      amount: totalAmount,
    });
    totalRow.font = { bold: true };
    totalRow.getCell("amount").numFmt = '#,##0';

    worksheet.autoFilter = {
      from: "A1",
      to: "J1",
    };

    return await workbook.xlsx.writeBuffer();
  }

  async exportExpensesCSV(
    tenantId: string,
    filters: ExportFilters
  ): Promise<string> {
    const expenses = await this.getExpenses(tenantId, filters);
    const headers = ["Date", "Receipt #", "Merchant", "Category", "Description", "Amount", "Tax", "Payment", "Status", "Tags"];

    const rows = expenses.map((exp) => [
      new Date(exp.expenseDate).toLocaleDateString("id-ID"),
      exp.receipt?.receiptData?.receiptNumber || "-",
      exp.receipt?.receiptData?.merchantName || "-",
      (exp.category as { name: string })?.name || "-",
      exp.description || "",
      exp.amount.toString(),
      exp.receipt?.receiptData?.taxAmount?.toString() || "0",
      exp.paymentMethod || "-",
      exp.status,
      (exp.tags as string[]).join(", "),
    ]);

    const escapeCSV = (val: string) =>
      val.includes(",") || val.includes('"') || val.includes("\n")
        ? `"${val.replace(/"/g, '""')}"`
        : val;

    return [
      headers.join(","),
      ...rows.map((row) => row.map(escapeCSV).join(",")),
    ].join("\n");
  }

  async exportExpensesPDF(
    tenantId: string,
    filters: ExportFilters
  ): Promise<Buffer> {
    return new Promise<Buffer>(async (resolve, reject) => {
      try {
        const expenses = await this.getExpenses(tenantId, filters);
        const chunks: Buffer[] = [];
        const doc = new PDFDocument({
          size: "A4",
          margin: 50,
          info: {
            Title: "Expense Report - JagaFinance",
            Author: "JagaFinance",
            CreationDate: new Date(),
          },
        });

        doc.on("data", (chunk) => chunks.push(chunk));
        doc.on("end", () => resolve(Buffer.concat(chunks)));

      doc.fontSize(20).font("Helvetica-Bold").text("Expense Report", {
        align: "center",
      });

      doc.fontSize(10).text(`Generated: ${new Date().toLocaleDateString("id-ID")}`, {
        align: "center",
      });
      doc.moveDown();

      const tableHeaders = ["Date", "Category", "Description", "Amount"];
      const colWidths = [80, 120, 200, 100];
      const startX = 50;
      let y = 140;

      doc.fontSize(9).font("Helvetica-Bold");
      let x = startX;
      for (let i = 0; i < tableHeaders.length; i++) {
        doc.text(tableHeaders[i], x, y, { width: colWidths[i] });
        x += colWidths[i];
      }

      y += 15;
      doc.moveTo(startX, y).lineTo(545, y).stroke();
      y += 10;

      let totalAmount = 0;
      doc.font("Helvetica");

      for (const exp of expenses) {
        if (y > 720) {
          doc.addPage();
          y = 50;
        }

        x = startX;
        const row = [
          new Date(exp.expenseDate).toLocaleDateString("id-ID"),
          (exp.category as { name: string })?.name || "-",
          exp.description || exp.title || "-",
          `Rp ${parseFloat(exp.amount.toString()).toLocaleString("id-ID")}`,
        ];

        for (let i = 0; i < row.length; i++) {
          doc.text(row[i], x, y, { width: colWidths[i] });
          x += colWidths[i];
        }

        totalAmount += parseFloat(exp.amount.toString());
        y += 15;
      }

      y += 10;
      doc.moveTo(startX, y).lineTo(545, y).stroke();
      y += 15;
      doc.font("Helvetica-Bold").fontSize(11);
      doc.text(`Total: Rp ${totalAmount.toLocaleString("id-ID")}`, startX, y);

        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  async exportForJurnal(
    tenantId: string,
    filters: ExportFilters
  ): Promise<string> {
    const expenses = await this.getExpenses(tenantId, filters);

    const headers = [
      "Date",
      "Journal Type",
      "Contact",
      "Reference Number",
      "Description",
      "Account",
      "Debit",
      "Credit",
      "Tax Rate",
      "Tax Amount",
      "Currency",
    ];

    const rows = expenses.map((exp) => {
      const amount = parseFloat(exp.amount.toString());
      const tax = exp.receipt?.receiptData?.taxAmount
        ? parseFloat(exp.receipt.receiptData.taxAmount.toString())
        : 0;
      const merchant = exp.receipt?.receiptData?.merchantName || "Various";

      const taxLine = tax > 0
        ? [
            new Date(exp.expenseDate).toLocaleDateString("id-ID"),
            "General Journal",
            merchant,
            exp.receipt?.receiptData?.receiptNumber || `EXP-${exp.id.slice(0, 8)}`,
            `${exp.title} - PPN`,
            "Tax Expense",
            tax.toString(),
            "0",
            "11",
            tax.toString(),
            "IDR",
          ]
        : [];

      return [
        [
          new Date(exp.expenseDate).toLocaleDateString("id-ID"),
          "General Journal",
          merchant,
          exp.receipt?.receiptData?.receiptNumber || `EXP-${exp.id.slice(0, 8)}`,
          exp.title,
          "Expense",
          amount.toString(),
          "0",
          "0",
          "0",
          "IDR",
        ],
        taxLine,
      ].filter(Boolean);
    }).flat(1);

    return [headers.join("\t"), ...rows.map((r) => (r as string[]).join("\t"))].join("\n");
  }

  async exportForAccurate(
    tenantId: string,
    filters: ExportFilters
  ): Promise<string> {
    const expenses = await this.getExpenses(tenantId, filters);

    const headers = [
      "Transaction Date",
      "Document Number",
      "Document Memo",
      "Item Name",
      "Quantity",
      "Unit Price",
      "Amount",
      "Tax",
      "Tax Rate",
      "Account",
      "Contact",
    ];

    const rows = expenses.map((exp) => {
      const amount = parseFloat(exp.amount.toString());
      return [
        new Date(exp.expenseDate).toLocaleDateString("id-ID"),
        `EXP-${exp.id.slice(0, 8)}`,
        exp.description || "",
        exp.title,
        "1",
        amount.toString(),
        amount.toString(),
        exp.receipt?.receiptData?.taxAmount?.toString() || "0",
        exp.receipt?.receiptData?.taxRate?.toString() || "0",
        "Expense",
        exp.receipt?.receiptData?.merchantName || "",
      ];
    });

    return [headers.join(","), ...rows.map((r) => r.map((v) => `"${v}"`).join(","))].join("\n");
  }

  private async getExpenses(tenantId: string, filters: ExportFilters) {
    const where: Record<string, unknown> = { tenantId };

    if (filters.date_from || filters.date_to) {
      where.expenseDate = {};
      if (filters.date_from) (where.expenseDate as Record<string, unknown>).gte = new Date(filters.date_from);
      if (filters.date_to) (where.expenseDate as Record<string, unknown>).lte = new Date(filters.date_to);
    }

    if (filters.category_id) where.categoryId = filters.category_id;
    if (filters.status) where.status = filters.status;

    return prisma.expense.findMany({
      where,
      include: {
        category: true,
        receipt: {
          include: { receiptData: true },
        },
      },
      orderBy: { expenseDate: "desc" },
    });
  }
}
