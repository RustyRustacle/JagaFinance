import vision from "@google-cloud/vision";
import { createWorker } from "tesseract.js";
import os from "os";
import fs from "fs";
import path from "path";

export interface OCRResult {
  merchantName: string | null;
  merchantAddress: string | null;
  merchantPhone: string | null;
  receiptNumber: string | null;
  transactionDate: Date | null;
  subtotal: number | null;
  taxAmount: number | null;
  taxRate: number | null;
  discountAmount: number | null;
  totalAmount: number;
  currency: string;
  paymentMethod: string | null;
  lineItems: LineItem[];
  confidence: number;
  rawText: string;
}

export interface LineItem {
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

export class OCRService {
  private visionClient: vision.ImageAnnotatorClient | null = null;

  constructor() {
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON) {
      const credPath = path.join(os.tmpdir(), "gcp-credentials.json");
      fs.writeFileSync(credPath, process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON);
      this.visionClient = new vision.ImageAnnotatorClient({
        keyFilename: credPath,
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      this.visionClient = new vision.ImageAnnotatorClient({
        keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
      });
    }
  }

  async processImage(imageBuffer: Buffer): Promise<OCRResult> {
    if (this.visionClient) {
      try {
        return await this.processWithGoogleVision(imageBuffer);
      } catch (error) {
        console.error("Google Vision failed, falling back to Tesseract:", error);
      }
    }

    return this.processWithTesseract(imageBuffer);
  }

  private async processWithGoogleVision(
    imageBuffer: Buffer
  ): Promise<OCRResult> {
    const [result] = await this.visionClient!.documentTextDetection({
      image: { content: imageBuffer },
    });

    const fullText = result.fullTextAnnotation?.text || "";
    const confidence = result.fullTextAnnotation?.confidence ?? 0;

    return this.parseText(fullText, confidence, "google_vision");
  }

  private async processWithTesseract(
    imageBuffer: Buffer
  ): Promise<OCRResult> {
    const worker = await createWorker("eng", 1, {
      cachePath: os.tmpdir() + "/tesseract",
    });

    const {
      data: { text, confidence },
    } = await worker.recognize(imageBuffer);

    await worker.terminate();

    return this.parseText(text, confidence / 100, "tesseract");
  }

  private parseText(
    text: string,
    confidence: number,
    provider: string
  ): OCRResult {
    const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
    const fullText = text.toLowerCase();

    const merchantName = this.extractMerchantName(lines, fullText);
    const receiptNumber = this.extractReceiptNumber(fullText);
    const transactionDate = this.extractDate(fullText);
    const { subtotal, taxAmount, totalAmount, discountAmount } =
      this.extractAmounts(text);
    const taxRate = this.extractTaxRate(fullText, taxAmount, subtotal);
    const lineItems = this.extractLineItems(lines);

    const currency = fullText.includes("idr") || fullText.includes("rp")
      ? "IDR"
      : "USD";

    return {
      merchantName,
      merchantAddress: this.extractAddress(lines),
      merchantPhone: this.extractPhone(fullText),
      receiptNumber,
      transactionDate,
      subtotal,
      taxAmount,
      taxRate,
      discountAmount,
      totalAmount,
      currency,
      paymentMethod: null,
      lineItems,
      confidence,
      rawText: text,
    };
  }

  private extractMerchantName(lines: string[], fullText: string): string | null {
    const skipWords = [
      "total", "subtotal", "tax", "date", "time", "receipt",
      "invoice", "payment", "cash", "card", "credit", "visa",
      "master", "amount", "balance", "change", "thank", "www",
    ];

    for (const line of lines.slice(0, 10)) {
      const lower = line.toLowerCase();
      if (line.length > 2 && line.length < 50) {
        const isSkip = skipWords.some((w) => lower.startsWith(w));
        const hasNumber = /\d/.test(line);
        if (!isSkip && !hasNumber && /^[A-Z]/.test(line)) {
          return line;
        }
      }
    }
    return null;
  }

  private extractAddress(lines: string[]): string | null {
    const addressKeywords = ["jl.", "jalan", "street", "st.", "rt/", "rw/", "kelurahan", "kecamatan"];
    for (const line of lines) {
      if (addressKeywords.some((kw) => line.toLowerCase().includes(kw))) {
        return line;
      }
    }
    return null;
  }

  private extractPhone(fullText: string): string | null {
    const phoneRegex = /(?:\+62|62|0)\d{8,12}/g;
    const match = fullText.match(phoneRegex);
    return match?.[0] || null;
  }

  private extractReceiptNumber(fullText: string): string | null {
    const patterns = [
      /(?:receipt|invoice|trx|no\.?|#)\s*[:#]?\s*([A-Z0-9-]+)/i,
      /(?:nomor|no)\s*[:#]?\s*([A-Z0-9-]+)/i,
    ];
    for (const pattern of patterns) {
      const match = fullText.match(pattern);
      if (match) return match[1];
    }
    return null;
  }

  private extractDate(fullText: string): Date | null {
    const patterns = [
      /(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})/,
      /(\d{2,4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})/,
      /(\d{1,2})\s+(jan|feb|mar|apr|mei|jun|jul|agu|sep|okt|nov|des)[a-z]*\s+(\d{2,4})/i,
    ];

    for (const pattern of patterns) {
      const match = fullText.match(pattern);
      if (match) {
        let year: number, month: number, day: number;

        const months: Record<string, number> = {
          jan: 0, feb: 1, mar: 2, apr: 3, mei: 4, jun: 5,
          jul: 6, agu: 7, sep: 8, okt: 9, nov: 10, des: 11,
        };

        if (months[match[2]?.toLowerCase()]) {
          day = parseInt(match[1]);
          month = months[match[2].toLowerCase()];
          year = parseInt(match[3]);
        } else if (parseInt(match[1]) > 31) {
          year = parseInt(match[1]);
          month = parseInt(match[2]) - 1;
          day = parseInt(match[3]);
        } else if (parseInt(match[3]) > 31) {
          day = parseInt(match[1]);
          month = parseInt(match[2]) - 1;
          year = parseInt(match[3]);
        } else {
          day = parseInt(match[1]);
          month = parseInt(match[2]) - 1;
          year = parseInt(match[3]) > 31 ? parseInt(match[3]) : parseInt(match[3]) + 2000;
        }

        if (year < 100) year += 2000;

        const date = new Date(year, month, day);
        if (!isNaN(date.getTime()) && date.getFullYear() >= 2000) {
          return date;
        }
      }
    }
    return null;
  }

  private extractAmounts(text: string) {
    const amounts = {
      subtotal: null as number | null,
      taxAmount: null as number | null,
      totalAmount: 0,
      discountAmount: null as number | null,
    };

    const lines = text.split("\n");

    for (const line of lines) {
      const cleaned = line.replace(/[,.]/g, (m, i, s) => {
        const next = s[i + 1];
        return next && /\d{3}/.test(s.substring(i + 1, i + 4)) ? "" : m;
      });

      const numbers = cleaned.match(/[\d]+(?:[.,]\d+)?/g) || [];
      const values = numbers.map(Number).filter((n) => n > 0);

      const lower = line.toLowerCase();

      if (lower.includes("total") || lower.includes("jumlah")) {
        if (!lower.includes("sub")) {
          const val = values[values.length - 1];
          if (val > (amounts.totalAmount || 0)) {
            amounts.totalAmount = val;
          }
        }
      }

      if (lower.includes("subtotal") || lower.includes("sub total")) {
        const val = values[values.length - 1];
        if (val > 0) amounts.subtotal = val;
      }

      if (lower.includes("tax") || lower.includes("pajak") || lower.includes("ppn")) {
        const val = values[values.length - 1];
        if (val > 0) amounts.taxAmount = val;
      }

      if (lower.includes("discount") || lower.includes("diskon")) {
        const val = values[values.length - 1];
        if (val > 0) amounts.discountAmount = val;
      }
    }

    if (amounts.totalAmount === 0) {
      const allNumbers = text.match(/\d[\d,.\s]*/g) || [];
      const values = allNumbers
        .map((s) => parseFloat(s.replace(/[,.]/g, "")))
        .filter((n) => n > 0 && n > 1000);
      if (values.length > 0) {
        amounts.totalAmount = Math.max(...values);
      }
    }

    return amounts;
  }

  private extractTaxRate(
    fullText: string,
    taxAmount: number | null,
    subtotal: number | null
  ): number | null {
    const percentageMatch = fullText.match(/(\d+)%/);
    if (percentageMatch) {
      return parseFloat(percentageMatch[1]);
    }

    if (taxAmount && subtotal && subtotal > 0) {
      return Math.round((taxAmount / subtotal) * 10000) / 100;
    }

    if (fullText.includes("ppn")) return 11;
    return null;
  }

  private extractLineItems(lines: string[]): LineItem[] {
    const items: LineItem[] = [];

    for (const line of lines) {
      const parts = line.split(/\s{2,}|\t/).filter(Boolean);
      if (parts.length >= 2) {
        const lastPart = parts[parts.length - 1];
        const amount = parseFloat(lastPart.replace(/[,.]/g, ""));
        if (amount > 0 && amount < 100000000) {
          items.push({
            description: parts.slice(0, -1).join(" ").trim(),
            quantity: 1,
            unitPrice: amount,
            amount,
          });
        }
      }
    }

    return items.slice(0, 50);
  }
}
