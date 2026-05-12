import { Router } from "express";
import { z } from "zod";
import { prisma } from "@jagafinance/db";
import { authMiddleware, AuthRequest, financeOrAdmin } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";

export const budgetRouter = Router();

const createBudgetSchema = z.object({
  category_id: z.string().uuid(),
  amount: z.number().positive(),
  currency: z.string().length(3).default("IDR"),
  period: z.enum(["MONTHLY", "QUARTERLY", "YEARLY"]).default("MONTHLY"),
  start_date: z.string().date(),
  end_date: z.string().date(),
  alert_threshold: z.number().min(0).max(100).default(80),
});

const updateBudgetSchema = createBudgetSchema.partial();

budgetRouter.use(authMiddleware);

budgetRouter.get("/", async (req: AuthRequest, res) => {
  const { period, is_active, category_id } = req.query;

  const where: Record<string, unknown> = {
    tenantId: req.user!.tenantId,
  };

  if (period) where.period = period;
  if (is_active !== undefined) where.isActive = is_active === "true";
  if (category_id) where.categoryId = category_id;

  const budgets = await prisma.budget.findMany({
    where,
    include: {
      category: true,
    },
    orderBy: { startDate: "asc" },
  });

  res.json({ success: true, data: budgets });
});

budgetRouter.post("/", financeOrAdmin, async (req: AuthRequest, res) => {
  const data = req.body;

  const budget = await prisma.budget.create({
    data: {
      tenantId: req.user!.tenantId,
      categoryId: data.category_id,
      amount: data.amount,
      currency: data.currency,
      period: data.period,
      startDate: new Date(data.start_date),
      endDate: new Date(data.end_date),
      alertThreshold: data.alert_threshold,
    },
    include: { category: true },
  });

  res.status(201).json({ success: true, data: budget });
});

budgetRouter.patch("/:id", financeOrAdmin, async (req: AuthRequest, res) => {
  const data = req.body;

  if (data.start_date) data.startDate = new Date(data.start_date);
  if (data.end_date) data.endDate = new Date(data.end_date);

  const budget = await prisma.budget.update({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
    data,
    include: { category: true },
  });

  res.json({ success: true, data: budget });
});

budgetRouter.delete("/:id", financeOrAdmin, async (req: AuthRequest, res) => {
  await prisma.budget.delete({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  res.json({ success: true });
});

budgetRouter.get("/:id/usage", async (req: AuthRequest, res) => {
  const budget = await prisma.budget.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
    include: { category: true },
  });

  if (!budget) {
    throw new AppError(404, "NOT_FOUND", "Budget not found");
  }

  const spent = await prisma.expense.aggregate({
    where: {
      tenantId: req.user!.tenantId,
      categoryId: budget.categoryId,
      expenseDate: {
        gte: budget.startDate,
        lte: budget.endDate,
      },
      status: { in: ["CONFIRMED", "RECONCILED"] },
    },
    _sum: { amount: true },
  });

  const totalSpent = spent._sum.amount?.toNumber() ?? 0;
  const remaining = budget.amount.toNumber() - totalSpent;
  const percentage = (totalSpent / budget.amount.toNumber()) * 100;

  res.json({
    success: true,
    data: {
      budget: {
        id: budget.id,
        amount: budget.amount.toNumber(),
        period: budget.period,
        startDate: budget.startDate,
        endDate: budget.endDate,
      },
      spent: totalSpent,
      remaining,
      percentage,
      category: {
        name: budget.category.name,
        nameEn: budget.category.nameEn,
      },
      alertTriggered: percentage >= budget.alertThreshold.toNumber(),
      nextThreshold: budget.alertThreshold.toNumber(),
    },
  });
});
