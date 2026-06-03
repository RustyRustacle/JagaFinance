import { Request, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import ws from "ws";
// Mengambil prisma, Role, dan InviteStatus langsung dari shared package database 
import { prisma, Role, InviteStatus } from "@jagafinance/db"; 


import { AppError } from "../middleware/errorHandler";
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment"
  );
}

const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: {
    transport: ws as any, // Tambahkan 'as any' di sini
  },
});

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
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      throw new AppError(401, "AUTH_REQUIRED", "Authentication required");
    }

    const token = authHeader.split(" ")[1];

    const { data: { user }, error } = await supabaseAnon.auth.getUser(token);
    if (error || !user) {
      throw new AppError(401, "AUTH_REQUIRED", error?.message || "Invalid or expired token");
    }

    const membership = await prisma.tenantMember.findFirst({
      where: {
        userId: user.id,
        status: InviteStatus.ACCEPTED,
      },
    });

    if (!membership) {
      throw new AppError(403, "FORBIDDEN", "No active tenant membership");
    }

    req.user = {
      id: user.id,
      email: user.email ?? "",
      tenantId: membership.tenantId,
      role: membership.role,
    };

    next();
  } catch (err) {
    next(err);
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