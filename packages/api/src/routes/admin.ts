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

adminRouter.get("/users/:id", async (req: AuthRequest, res) => {
  const { id } = req.params;

  const member = await prisma.tenantMember.findFirst({
    where: { userId: id },
    include: {
      tenant: true,
      inviter: { select: { email: true } },
    },
  });

  if (!member) {
    res.status(404).json({ success: false, error: { message: "User tidak ditemukan" } });
    return;
  }

  let email = "unknown@email.com";
  try {
    const { data: supabaseUser } = await supabase.auth.admin.getUserById(id);
    if (supabaseUser?.user) email = supabaseUser.user.email ?? email;
  } catch {}

  const receiptCount = await prisma.receipt.count({ where: { uploadedBy: id } });
  const expenseCount = await prisma.expense.count({ where: { createdBy: id } });

  res.json({
    success: true,
    data: {
      id: member.userId,
      email,
      role: member.role,
      status: member.status,
      tenant: { id: member.tenant.id, name: member.tenant.name, slug: member.tenant.slug },
      invitedBy: member.inviter?.email ?? null,
      invitedAt: member.invitedAt,
      acceptedAt: member.acceptedAt,
      createdAt: member.createdAt,
      updatedAt: member.updatedAt,
      receiptCount,
      expenseCount,
    },
  });
});

adminRouter.get("/receipts/:id", async (req: AuthRequest, res) => {
  const { id } = req.params;

  const receipt = await prisma.receipt.findUnique({
    where: { id },
    include: {
      tenant: { select: { id: true, name: true, slug: true } },
      uploader: { select: { email: true } },
      receiptData: {
        include: { verifier: { select: { email: true } } },
      },
      expense: {
        include: { category: { select: { id: true, name: true } } },
      },
    },
  });

  if (!receipt) {
    res.status(404).json({ success: false, error: { message: "Struk tidak ditemukan" } });
    return;
  }

  res.json({
    success: true,
    data: {
      id: receipt.id,
      tenant: receipt.tenant,
      uploader: receipt.uploader,
      fileName: receipt.fileName,
      fileType: receipt.fileType,
      fileSize: receipt.fileSize,
      fileUrl: receipt.fileUrl,
      status: receipt.status,
      ocrProvider: receipt.ocrProvider,
      ocrConfidence: receipt.ocrConfidence,
      errorMessage: receipt.errorMessage,
      processedAt: receipt.processedAt,
      createdAt: receipt.createdAt,
      updatedAt: receipt.updatedAt,
      blockchainTxHash: receipt.blockchainTxHash,
      blockchainStatus: receipt.blockchainStatus,
      blockchainNetwork: receipt.blockchainNetwork,
      blockchainSubmittedAt: receipt.blockchainSubmittedAt,
      blockchainConfirmedAt: receipt.blockchainConfirmedAt,
      receiptData: receipt.receiptData
        ? {
            merchantName: receipt.receiptData.merchantName,
            merchantAddress: receipt.receiptData.merchantAddress,
            merchantPhone: receipt.receiptData.merchantPhone,
            receiptNumber: receipt.receiptData.receiptNumber,
            transactionDate: receipt.receiptData.transactionDate,
            subtotal: receipt.receiptData.subtotal,
            taxAmount: receipt.receiptData.taxAmount,
            taxRate: receipt.receiptData.taxRate,
            discountAmount: receipt.receiptData.discountAmount,
            totalAmount: receipt.receiptData.totalAmount,
            currency: receipt.receiptData.currency,
            paymentMethod: receipt.receiptData.paymentMethod,
            lineItems: receipt.receiptData.lineItems,
            isVerified: receipt.receiptData.isVerified,
            verifier: receipt.receiptData.verifier,
            verificationNotes: receipt.receiptData.verificationNotes,
            createdAt: receipt.receiptData.createdAt,
          }
        : null,
      expense: receipt.expense
        ? {
            id: receipt.expense.id,
            title: receipt.expense.title,
            amount: receipt.expense.amount,
            status: receipt.expense.status,
            category: receipt.expense.category,
            expenseDate: receipt.expense.expenseDate,
          }
        : null,
    },
  });
});

adminRouter.get("/receipts", async (_req: AuthRequest, res) => {
  const page = Math.max(1, parseInt(_req.query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(_req.query.limit as string) || 20));
  const search = (_req.query.search as string) || "";

  const where = search
    ? { fileName: { contains: search, mode: "insensitive" as const } }
    : {};

  const [receipts, total] = await Promise.all([
    prisma.receipt.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: "desc" },
      include: {
        tenant: { select: { name: true } },
        uploader: { select: { email: true } },
        receiptData: { select: { totalAmount: true } },
      },
    }),
    prisma.receipt.count({ where }),
  ]);

  res.json({
    success: true,
    data: receipts.map((r) => ({
      id: r.id,
      fileName: r.fileName,
      fileType: r.fileType,
      status: r.status,
      totalAmount: r.receiptData?.totalAmount ?? null,
      uploaderEmail: r.uploader.email,
      tenantName: r.tenant.name,
      createdAt: r.createdAt,
    })),
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
