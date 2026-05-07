import { Router } from "express";
import { prisma } from "@vaultledger/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";

export const dashboardRouter = Router();

dashboardRouter.use(authMiddleware);

dashboardRouter.get("/overview", async (req: AuthRequest, res) => {
  const tenantId = req.user!.tenantId;
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

  const [
    totalExpenses,
    totalReceipts,
    pendingReviews,
    budgetAlerts,
    expensesByCategory,
    monthlyTrend,
  ] = await Promise.all([
    prisma.expense.aggregate({
      where: {
        tenantId,
        expenseDate: { gte: monthStart, lte: monthEnd },
      },
      _sum: { amount: true },
    }),

    prisma.receipt.count({
      where: {
        tenantId,
        createdAt: { gte: monthStart, lte: monthEnd },
      },
    }),

    prisma.receipt.count({
      where: {
        tenantId,
        status: "PROCESSING",
      },
    }),

    prisma.budgetAlert.count({
      where: {
        tenantId,
        triggeredAt: { gte: monthStart },
      },
    }),

    prisma.expense.groupBy({
      by: ["categoryId"],
      where: {
        tenantId,
        expenseDate: { gte: monthStart, lte: monthEnd },
      },
      _sum: { amount: true },
      _count: true,
    }),

    (async () => {
      const months = [];
      for (let i = 2; i >= 0; i--) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthEnd = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59);
        const result = await prisma.expense.aggregate({
          where: {
            tenantId,
            expenseDate: { gte: date, lte: monthEnd },
          },
          _sum: { amount: true },
        });
        months.push({
          month: date.toISOString().slice(0, 7),
          amount: result._sum.amount?.toNumber() ?? 0,
        });
      }
      return months;
    })(),
  ]);

  const categoryDetails = await Promise.all(
    expensesByCategory.map(async (e) => {
      const cat = await prisma.expenseCategory.findUnique({
        where: { id: e.categoryId },
      });
      return {
        category: cat?.name ?? "Unknown",
        amount: e._sum.amount?.toNumber() ?? 0,
        percentage: 0,
      };
    })
  );

  const total = totalExpenses._sum.amount?.toNumber() ?? 0;
  categoryDetails.forEach((c) => {
    c.percentage = total > 0 ? (c.amount / total) * 100 : 0;
  });

  res.json({
    success: true,
    data: {
      total_expenses: total,
      total_receipts: totalReceipts,
      pending_reviews: pendingReviews,
      budget_alerts: budgetAlerts,
      expenses_by_category: categoryDetails,
      monthly_trend: monthlyTrend,
    },
  });
});
