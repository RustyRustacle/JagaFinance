import { Router } from "express";
import { prisma } from "@jagafinance/db";
import { supabase } from "../lib/supabase";
import { authMiddleware, adminOnly, AuthRequest } from "../middleware/auth";

export const adminRouter = Router();

adminRouter.use(authMiddleware, adminOnly);

adminRouter.get("/stats", async (_req: AuthRequest, res) => {
  const [
    tenantCount,
    memberCount,
    receiptCount,
    expenseCount,
    budgetCount,
    totalReceiptAmount,
    totalExpenseAmount,
    recentTenants,
    recentMembers,
  ] = await Promise.all([
    prisma.tenant.count(),
    prisma.tenantMember.count(),
    prisma.receipt.count(),
    prisma.expense.count(),
    prisma.budget.count(),
    prisma.receiptData.aggregate({ _sum: { totalAmount: true } }),
    prisma.expense.aggregate({ _sum: { amount: true } }),
    prisma.tenant.findMany({ orderBy: { createdAt: "desc" }, take: 5 }),
    prisma.tenantMember.findMany({
      orderBy: { createdAt: "desc" },
      take: 10,
      include: { tenant: { select: { name: true } } },
    }),
  ]);

  const receiptStatuses = await prisma.receipt.groupBy({
    by: ["status"],
    _count: true,
  });

  const expenseStatuses = await prisma.expense.groupBy({
    by: ["status"],
    _count: true,
  });

  const monthlyReceipts = await prisma.$queryRaw<Array<{ month: string; count: bigint; total: number }>>`
    SELECT to_char(created_at, 'YYYY-MM') as month, COUNT(*)::int as count, COALESCE(SUM(rd.total_amount), 0) as total
    FROM receipts r LEFT JOIN receipt_data rd ON rd.receipt_id = r.id
    WHERE created_at >= NOW() - INTERVAL '12 months'
    GROUP BY month ORDER BY month
  `;

  res.json({
    success: true,
    data: {
      counts: {
        tenants: tenantCount,
        members: memberCount,
        receipts: receiptCount,
        expenses: expenseCount,
        budgets: budgetCount,
      },
      totals: {
        receiptAmount: totalReceiptAmount._sum.totalAmount ?? 0,
        expenseAmount: totalExpenseAmount._sum.amount ?? 0,
      },
      receiptStatuses: receiptStatuses.reduce((acc, r) => ({ ...acc, [r.status]: r._count }), {} as Record<string, number>),
      expenseStatuses: expenseStatuses.reduce((acc, r) => ({ ...acc, [r.status]: r._count }), {} as Record<string, number>),
      monthlyTrend: monthlyReceipts.map((r) => ({ month: r.month, count: Number(r.count), total: Number(r.total) })),
      recentTenants: recentTenants.map((t) => ({ id: t.id, name: t.name, slug: t.slug, createdAt: t.createdAt })),
      recentMembers: recentMembers.map((m) => ({
        userId: m.userId,
        tenantName: m.tenant.name,
        role: m.role,
        createdAt: m.createdAt,
      })),
    },
  });
});

adminRouter.get("/users", async (_req: AuthRequest, res) => {
  const page = Math.max(1, parseInt(_req.query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(_req.query.limit as string) || 20));
  const search = (_req.query.search as string) || "";

  const where = search
    ? { user: { email: { contains: search, mode: "insensitive" as const } } }
    : {};

  const [members, total] = await Promise.all([
    prisma.tenantMember.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: "desc" },
      include: {
        tenant: { select: { id: true, name: true, slug: true } },
      },
    }),
    prisma.tenantMember.count({ where }),
  ]);

  const userIds = [...new Set(members.map((m) => m.userId))];

  let userEmails: Record<string, string> = {};
  try {
    const { data: supabaseUsers } = await supabase.auth.admin.listUsers();
    if (supabaseUsers?.users) {
      userEmails = Object.fromEntries(supabaseUsers.users.map((u) => [u.id, u.email ?? ""]));
    }
  } catch {}

  const users = members.map((m) => ({
    id: m.userId,
    email: userEmails[m.userId] || "unknown@email.com",
    role: m.role,
    status: m.status,
    tenant: m.tenant,
    createdAt: m.createdAt,
    acceptedAt: m.acceptedAt,
  }));

  const uniqueUsers = Object.values(
    users.reduce((acc, u) => {
      if (!acc[u.id]) acc[u.id] = u;
      return acc;
    }, {} as Record<string, typeof users[0]>)
  );

  res.json({
    success: true,
    data: uniqueUsers,
    meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
});

adminRouter.get("/tenants", async (_req: AuthRequest, res) => {
  const page = Math.max(1, parseInt(_req.query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(_req.query.limit as string) || 20));
  const search = (_req.query.search as string) || "";

  const where = search
    ? { name: { contains: search, mode: "insensitive" as const } }
    : {};

  const [tenants, total] = await Promise.all([
    prisma.tenant.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: "desc" },
      include: {
        _count: { select: { members: true, receipts: true, expenses: true, budgets: true } },
      },
    }),
    prisma.tenant.count({ where }),
  ]);

  const tenantData = await Promise.all(
    tenants.map(async (t) => {
      const receiptAgg = await prisma.receiptData.aggregate({
        where: { receipt: { tenantId: t.id } },
        _sum: { totalAmount: true },
      });
      return {
        id: t.id,
        name: t.name,
        slug: t.slug,
        language: t.language,
        currency: t.currency,
        isActive: t.isActive,
        memberCount: t._count.members,
        receiptCount: t._count.receipts,
        expenseCount: t._count.expenses,
        budgetCount: t._count.budgets,
        totalReceiptAmount: receiptAgg._sum.totalAmount ?? 0,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      };
    })
  );

  res.json({
    success: true,
    data: tenantData,
    meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
});
