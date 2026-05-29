import { describe, it, expect } from "vitest";
import { z } from "zod";

describe("Expense Schema Validation", () => {
  const createExpenseSchema = z.object({
    receipt_id: z.string().uuid().optional(),
    category_id: z.string().uuid(),
    title: z.string().min(1).max(255),
    description: z.string().optional(),
    amount: z.number().positive(),
    currency: z.string().length(3).default("IDR"),
    expense_date: z.string().datetime().or(z.string().date()),
    payment_method: z.string().max(50).optional(),
    tax_deductible: z.boolean().default(false),
    tags: z.array(z.string().max(50)).optional(),
    cost_center: z.string().max(100).optional(),
    project_code: z.string().max(100).optional(),
    metadata: z.record(z.unknown()).optional(),
  });

  it("should accept valid expense data", () => {
    const result = createExpenseSchema.safeParse({
      category_id: "550e8400-e29b-41d4-a716-446655440000",
      title: "Test Expense",
      amount: 100000,
      expense_date: "2026-05-29",
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.currency).toBe("IDR");
      expect(result.data.tax_deductible).toBe(false);
    }
  });

  it("should reject negative amount", () => {
    const result = createExpenseSchema.safeParse({
      category_id: "550e8400-e29b-41d4-a716-446655440000",
      title: "Test Expense",
      amount: -100,
      expense_date: "2026-05-29",
    });
    expect(result.success).toBe(false);
  });

  it("should reject empty title", () => {
    const result = createExpenseSchema.safeParse({
      category_id: "550e8400-e29b-41d4-a716-446655440000",
      title: "",
      amount: 100,
      expense_date: "2026-05-29",
    });
    expect(result.success).toBe(false);
  });

  it("should reject invalid UUID for category_id", () => {
    const result = createExpenseSchema.safeParse({
      category_id: "not-a-uuid",
      title: "Test",
      amount: 100,
      expense_date: "2026-05-29",
    });
    expect(result.success).toBe(false);
  });

  it("should reject missing required fields", () => {
    const result = createExpenseSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it("should accept expense with all optional fields", () => {
    const result = createExpenseSchema.safeParse({
      category_id: "550e8400-e29b-41d4-a716-446655440000",
      title: "Test",
      amount: 50000,
      expense_date: "2026-05-29T10:00:00Z",
      description: "A test expense",
      payment_method: "CASH",
      tax_deductible: true,
      tags: ["office", "supplies"],
      cost_center: "HQ",
      project_code: "PRJ-001",
      metadata: { invoice_number: "INV-001" },
    });
    expect(result.success).toBe(true);
  });
});
