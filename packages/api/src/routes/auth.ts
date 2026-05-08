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

// function generateToken(payload: Record<string, string>) {
//   return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: "1h" });
// }

// function generateRefreshToken(payload: Record<string, string>) {
//   return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: "7d" });
// }

function generateToken(payload: Record<string, string>) {
  // Kita harus men-decode JWT_SECRET dari Base64 ke Buffer
  const secret = Buffer.from(process.env.JWT_SECRET!, 'base64');
  
  return jwt.sign(
    {
      ...payload,
      aud: "authenticated",           // WAJIB untuk Supabase
      role: "authenticated",          // WAJIB untuk Supabase
      sub: payload.userId,            // WAJIB: ID User
    },
    secret,                           // Gunakan secret yang sudah jadi Buffer
    { expiresIn: "1h", algorithm: "HS256" }
  );
}

function generateRefreshToken(payload: Record<string, string>) {
  const secret = Buffer.from(process.env.JWT_SECRET!, 'base64');
  
  return jwt.sign(
    {
      ...payload,
      aud: "authenticated",
      role: "authenticated",
      sub: payload.userId,
    },
    secret,
    { expiresIn: "7d", algorithm: "HS256" }
  );
}

authRouter.post("/login", validate(loginSchema), async (req, res) => {
  const { email, password } = req.body;

  // 1. Login ke Supabase secara resmi
  const { data: authData, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error || !authData.user || !authData.session) {
    throw new AppError(401, "AUTH_REQUIRED", "Invalid email or password");
  }

  // ... (Logika Prisma kamu tetap di sini untuk cek membership) ...
  const memberships = await prisma.tenantMember.findMany({
    where: { userId: authData.user.id, status: "ACCEPTED" },
    include: { tenant: true }
  });

  if (memberships.length === 0) throw new AppError(403, "FORBIDDEN", "No active tenant");

  // 2. JANGAN pakai generateToken(). Pakai token asli dari Supabase!
  const accessToken = authData.session.access_token; 
  const refreshToken = authData.session.refresh_token;

  res.json({
    success: true,
    data: {
      user: {
        id: authData.user.id,
        email: authData.user.email,
        name: authData.user.user_metadata?.name,
      },
      tenants: memberships.map((m) => ({ id: m.tenant.id, role: m.role })),
      accessToken, // Ini sekarang token ASLI Supabase
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
    email: authData.user.email ?? "",
  });

  const refreshToken = generateRefreshToken({
    userId: authData.user.id,
    tenantId: defaultMembership.tenantId,
    role: defaultMembership.role,
    email: authData.user.email ?? "",
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
    email: decoded.email ?? "",
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
