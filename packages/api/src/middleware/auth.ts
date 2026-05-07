import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { AppError } from "./errorHandler";
import { Role } from "@prisma/client";
import { prisma } from "@vaultledger/db";

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    tenantId: string;
    role: Role;
  };
  apiKey?: {
    id: string;
    tenantId: string;
    permissions: string[];
  };
}

export const authMiddleware = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw new AppError(401, "AUTH_REQUIRED", "Authentication required");
  }

  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      userId: string;
      tenantId: string;
      role: Role;
    };

    const member = await prisma.tenantMember.findFirst({
      where: {
        userId: decoded.userId,
        tenantId: decoded.tenantId,
        status: "ACCEPTED",
      },
    });

    if (!member) {
      throw new AppError(403, "FORBIDDEN", "Access denied to this tenant");
    }

    req.user = {
      id: decoded.userId,
      email: decoded.email as string,
      tenantId: decoded.tenantId,
      role: member.role,
    };

    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      throw new AppError(401, "AUTH_REQUIRED", "Invalid or expired token");
    }
    throw error;
  }
};

export function requireRole(...roles: Role[]) {
  return (req: AuthRequest, _res: Response, next: NextFunction) => {
    if (!req.user) {
      throw new AppError(401, "AUTH_REQUIRED", "Authentication required");
    }

    if (!roles.includes(req.user.role)) {
      throw new AppError(
        403,
        "FORBIDDEN",
        `Requires one of: ${roles.join(", ")}`
      );
    }

    next();
  };
}

export function requirePermission(permission: string) {
  return (req: AuthRequest, _res: Response, next: NextFunction) => {
    if (!req.user && !req.apiKey) {
      throw new AppError(401, "AUTH_REQUIRED", "Authentication required");
    }

    if (req.apiKey) {
      if (!req.apiKey.permissions.includes(permission)) {
        throw new AppError(
          403,
          "FORBIDDEN",
          `API key missing permission: ${permission}`
        );
      }
    }

    next();
  };
}

export const adminOnly = requireRole("ADMIN");
export const financeOrAdmin = requireRole("FINANCE", "ADMIN");
