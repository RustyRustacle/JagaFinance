import { Router } from "express";
import { z } from "zod";
import { prisma, Prisma } from "@vaultledger/db";
import { authMiddleware, AuthRequest, financeOrAdmin, adminOnly } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";
import { enqueueBudgetAlert } from "../lib/queue";

export const expenseRouter = Router();

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

const updateExpenseSchema = createExpenseSchema.partial();

const bulkUpdateSchema = z.object({
  ids: z.array(z.string().uuid()),
  updates: updateExpenseSchema,
});

const listQuerySchema = z.object({
  category_id: z.string().uuid().optional(),
  status: z.string().optional(),
  date_from: z.string().optional(),
  date_to: z.string().optional(),
  tags: z.string().optional(),
  created_by: z.string().uuid().optional(),
  search: z.string().optional(),
  sort: z.string().default("expense_date"),
  order: z.enum(["asc", "desc"]).default("desc"),
  page: z.coerce.number().default(1),
  limit: z.coerce.number().default(20),
});

expenseRouter.use(authMiddleware);

expenseRouter.post(
  "/",
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    const data = req.body;
    const expenseDate = new Date(data.expense_date);

    const expense = await prisma.expense.create({
      data: {
        tenantId: req.user!.tenantId,
        receiptId: data.receipt_id ?? null,
        categoryId: data.category_id,
        createdBy: req.user!.id,
        title: data.title,
        description: data.description,
        amount: data.amount,
        currency: data.currency,
        expenseDate,
        paymentMethod: data.payment_method,
        taxDeductible: data.tax_deductible,
        tags: data.tags ?? [],
        costCenter: data.cost_center,
        projectCode: data.project_code,
        metadata: data.metadata ?? {},
      },
      include: {
        category: true,
        receipt: true,
        creator: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.status(201).json({ success: true, data: expense });

    const budgets = await prisma.budget.findMany({
      where: {
        tenantId: req.user!.tenantId,
        categoryId: data.category_id,
        isActive: true,
        startDate: { lte: expenseDate },
        endDate: { gte: expenseDate },
      },
    });

    for (const budget of budgets) {
      await enqueueBudgetAlert(budget.id);
    }
  }
);

expenseRouter.get("/", async (req: AuthRequest, res) => {
  const parsed = listQuerySchema.safeParse(req.query);
  const query = parsed.success ? parsed.data : { page: 1, limit: 20, sort: "expense_date", order: "desc" };

  const where: Record<string, unknown> = {
    tenantId: req.user!.tenantId,
  };

  if (query.category_id) where.categoryId = query.category_id;
  if (query.status) where.status = query.status;
  if (query.created_by) where.createdBy = query.created_by;
  if (query.search) {
    where.OR = [
      { title: { contains: query.search, mode: "insensitive" } },
      { description: { contains: query.search, mode: "insensitive" } },
    ];
  }
  if (query.date_from || query.date_to) {
    where.expenseDate = {};
    if (query.date_from) (where.expenseDate as Record<string, unknown>).gte = new Date(query.date_from);
    if (query.date_to) (where.expenseDate as Record<string, unknown>).lte = new Date(query.date_to);
  }
  if (query.tags) {
    where.tags = { hasSome: query.tags.split(",") };
  }

  const [expenses, total] = await Promise.all([
    prisma.expense.findMany({
      where,
      include: {
        category: true,
        receipt: true,
        creator: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { [query.sort]: query.order },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    }),
    prisma.expense.count({ where }),
  ]);

  res.json({
    success: true,
    data: expenses,
    meta: {
      page: query.page,
      limit: query.limit,
      total,
      totalPages: Math.ceil(total / query.limit),
    },
  });
});

expenseRouter.get("/:id", async (req: AuthRequest, res) => {
  const expense = await prisma.expense.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
    include: {
      category: true,
      receipt: { include: { receiptData: true } },
      creator: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });

  if (!expense) {
    throw new AppError(404, "NOT_FOUND", "Expense not found");
  }

  res.json({ success: true, data: expense });
});

expenseRouter.patch(
  "/:id",
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    const data = req.body as Record<string, unknown>;

    if (data.expense_date) {
      data.expenseDate = new Date(data.expense_date as string);
      delete data.expense_date;
    }

    const expense = await prisma.expense.update({
      where: {
        id: req.params.id,
        tenantId: req.user!.tenantId,
      },
      data,
      include: { category: true },
    });

    res.json({ success: true, data: expense });
  }
);

expenseRouter.delete("/:id", adminOnly, async (req: AuthRequest, res) => {
  await prisma.expense.delete({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  res.json({ success: true });
});

expenseRouter.patch(
  "/bulk",
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    const { ids, updates } = req.body as { ids: string[]; updates: Record<string, unknown> };

    const updated = await prisma.expense.updateMany({
      where: {
        id: { in: ids },
        tenantId: req.user!.tenantId,
      },
      data: updates,
    });

    res.json({ success: true, data: { count: updated.count } });
  }
);
