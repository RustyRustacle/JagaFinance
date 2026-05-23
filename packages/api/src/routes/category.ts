import { Router } from "express";
import { z } from "zod";
import { prisma } from "@jagafinance/db";
import { authMiddleware, AuthRequest, financeOrAdmin } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";

export const categoryRouter = Router();

const createCategorySchema = z.object({
  name: z.string().min(1).max(100),
  name_en: z.string().max(100).optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).default("#6B7280"),
  icon: z.string().max(50).optional(),
  parent_id: z.string().uuid().nullish(),
  sort_order: z.number().default(0),
});

const updateCategorySchema = createCategorySchema.partial();

categoryRouter.use(authMiddleware);

categoryRouter.get("/", async (req: AuthRequest, res) => {
  const { is_active, parent_id } = req.query;

  const where: Record<string, unknown> = {
    tenantId: req.user!.tenantId,
  };

  if (is_active !== undefined) {
    where.isActive = is_active === "true";
  }

  if (parent_id) {
    where.parentId = parent_id;
  }

  const categories = await prisma.expenseCategory.findMany({
    where,
    include: {
      parent: {
        select: {
          id: true,
          name: true,
        },
      },
      _count: {
        select: { expenses: true },
      },
    },
    orderBy: { sortOrder: "asc" },
  });

  res.json({ success: true, data: categories });
});

categoryRouter.post("/", financeOrAdmin, async (req: AuthRequest, res) => {
  const data = req.body;

  const category = await prisma.expenseCategory.create({
    data: {
      tenantId: req.user!.tenantId,
      name: data.name,
      nameEn: data.name_en,
      color: data.color,
      icon: data.icon,
      parentId: data.parent_id,
      sortOrder: data.sort_order,
    },
  });

  res.status(201).json({ success: true, data: category });
});

categoryRouter.patch("/:id", financeOrAdmin, async (req: AuthRequest, res) => {
  const data = req.body;

  const category = await prisma.expenseCategory.update({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
    data,
  });

  res.json({ success: true, data: category });
});

categoryRouter.delete("/:id", financeOrAdmin, async (req: AuthRequest, res) => {
  const hasExpenses = await prisma.expense.count({
    where: {
      categoryId: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  if (hasExpenses > 0) {
    throw new AppError(
      409,
      "CONFLICT",
      "Cannot delete category with existing expenses"
    );
  }

  await prisma.expenseCategory.delete({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  res.json({ success: true });
});
