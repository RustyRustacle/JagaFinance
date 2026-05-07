import { Router } from "express";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { prisma } from "@vaultledger/db";
import { supabase } from "../lib/supabase";
import { validate } from "../middleware/validate";
import { authMiddleware, AuthRequest } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";

export const authRouter = Router();

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2).max(100),
  tenantName: z.string().min(2).max(100),
  tenantSlug: z.string().min(2).max(50).regex(/^[a-z0-9-]+$/),
  language: z.string().default("id"),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function generateToken(payload: Record<string, string>) {
  return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: "1h" });
}

function generateRefreshToken(payload: Record<string, string>) {
  return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: "7d" });
}

authRouter.post("/register", validate(registerSchema), async (req, res) => {
  const { email, password, name, tenantName, tenantSlug, language } = req.body;

  const existing = await supabase.auth.admin.listUsers();
  const userExists = existing.data.users.some((u) => u.email === email);
  if (userExists) {
    throw new AppError(409, "DUPLICATE", "Email already registered");
  }

  const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { name },
  });

  if (authError || !authUser.user) {
    throw new AppError(400, "AUTH_ERROR", authError?.message || "Failed to create user");
  }

  const tenant = await prisma.tenant.create({
    data: {
      name: tenantName,
      slug: tenantSlug,
      language,
    },
  });

  await prisma.tenantMember.create({
    data: {
      tenantId: tenant.id,
      userId: authUser.user.id,
      role: "ADMIN",
      status: "ACCEPTED",
      acceptedAt: new Date(),
    },
  });

  const accessToken = generateToken({
    userId: authUser.user.id,
    tenantId: tenant.id,
    role: "ADMIN",
  });

  const refreshToken = generateRefreshToken({
    userId: authUser.user.id,
    tenantId: tenant.id,
    role: "ADMIN",
  });

  res.status(201).json({
    success: true,
    data: {
      user: {
        id: authUser.user.id,
        email,
        name,
      },
      tenant: {
        id: tenant.id,
        name: tenantName,
        slug: tenantSlug,
      },
      accessToken,
      refreshToken,
    },
  });
});

authRouter.post("/login", validate(loginSchema), async (req, res) => {
  const { email, password } = req.body;

  const { data: authData, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error || !authData.user) {
    throw new AppError(401, "AUTH_REQUIRED", "Invalid email or password");
  }

  const memberships = await prisma.tenantMember.findMany({
    where: {
      userId: authData.user.id,
      status: "ACCEPTED",
    },
    include: {
      tenant: true,
    },
  });

  if (memberships.length === 0) {
    throw new AppError(403, "FORBIDDEN", "No active tenant membership");
  }

  const defaultMembership = memberships[0];

  const accessToken = generateToken({
    userId: authData.user.id,
    tenantId: defaultMembership.tenantId,
    role: defaultMembership.role,
  });

  const refreshToken = generateRefreshToken({
    userId: authData.user.id,
    tenantId: defaultMembership.tenantId,
    role: defaultMembership.role,
  });

  res.json({
    success: true,
    data: {
      user: {
        id: authData.user.id,
        email: authData.user.email,
        name: authData.user.user_metadata?.name,
      },
      tenants: memberships.map((m) => ({
        id: m.tenant.id,
        name: m.tenant.name,
        slug: m.tenant.slug,
        role: m.role,
      })),
      accessToken,
      refreshToken,
    },
  });
});

authRouter.post("/refresh", async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    throw new AppError(400, "VALIDATION_ERROR", "Refresh token required");
  }

  const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET!) as Record<string, string>;

  const newAccessToken = generateToken({
    userId: decoded.userId,
    tenantId: decoded.tenantId,
    role: decoded.role,
  });

  res.json({
    success: true,
    data: {
      accessToken: newAccessToken,
      refreshToken,
    },
  });
});

authRouter.post("/logout", authMiddleware, async (req: AuthRequest, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (token) {
    await supabase.auth.admin.signOut(token);
  }
  res.json({ success: true });
});
