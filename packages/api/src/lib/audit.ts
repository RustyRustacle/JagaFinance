import { prisma } from "@jagafinance/db";
import type { AuditAction } from "@jagafinance/db";
import type { Request } from "express";

export async function createAuditLog(params: {
  tenantId: string;
  userId?: string | null;
  action: AuditAction;
  entityType: string;
  entityId?: string | null;
  changes?: unknown;
  req?: Request;
}) {
  const { tenantId, userId, action, entityType, entityId, changes, req } = params;

  try {
    await prisma.auditLog.create({
      data: {
        tenantId,
        userId: userId ?? undefined,
        action,
        entityType,
        entityId: entityId ?? undefined,
        changes: changes ?? undefined,
        ipAddress: req?.ip ?? req?.socket?.remoteAddress ?? null,
        userAgent: req?.headers?.["user-agent"] ?? null,
      },
    });
  } catch (err) {
    console.error("Audit log failed:", err);
  }
}
