import { Router } from "express";
import { z } from "zod";
import { prisma } from "@vaultledger/db";
import { authMiddleware, AuthRequest, financeOrAdmin } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { AppError } from "../middleware/errorHandler";

export const tenantRouter = Router();

const updateTenantSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  industry: z.string().max(100).optional(),
  currency: z.string().length(3).optional(),
  timezone: z.string().max(50).optional(),
  language: z.string().max(5).optional(),
  settings: z.record(z.unknown()).optional(),
});

tenantRouter.use(authMiddleware);

tenantRouter.get("/current", async (req: AuthRequest, res) => {
  const tenant = await prisma.tenant.findUnique({
    where: { id: req.user!.tenantId },
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              name: true,
              avatarUrl: true,
            },
          },
        },
      },
    },
  });

  if (!tenant) {
    throw new AppError(404, "TENANT_NOT_FOUND", "Tenant not found");
  }

  res.json({ success: true, data: tenant });
});

tenantRouter.patch(
  "/current",
  validate(updateTenantSchema),
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    const tenant = await prisma.tenant.update({
      where: { id: req.user!.tenantId },
      data: req.body,
    });

    res.json({ success: true, data: tenant });
  }
);

tenantRouter.get("/current/members", async (req: AuthRequest, res) => {
  const members = await prisma.tenantMember.findMany({
    where: { tenantId: req.user!.tenantId },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          name: true,
          avatarUrl: true,
        },
      },
      inviter: {
        select: {
          id: true,
          email: true,
          name: true,
        },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ success: true, data: members });
});

tenantRouter.patch(
  "/current/members/:memberId",
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    const { role } = req.body as { role?: string };

    if (!role || !["ADMIN", "FINANCE", "VIEWER"].includes(role)) {
      throw new AppError(400, "VALIDATION_ERROR", "Invalid role");
    }

    const member = await prisma.tenantMember.update({
      where: {
        id: req.params.memberId,
        tenantId: req.user!.tenantId,
      },
      data: { role: role as "ADMIN" | "FINANCE" | "VIEWER" },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });

    res.json({ success: true, data: member });
  }
);

tenantRouter.delete(
  "/current/members/:memberId",
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    await prisma.tenantMember.delete({
      where: {
        id: req.params.memberId,
        tenantId: req.user!.tenantId,
      },
    });

    res.json({ success: true });
  }
);
