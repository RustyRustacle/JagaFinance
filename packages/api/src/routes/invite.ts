import { Router } from "express";
import { z } from "zod";
import crypto from "crypto";
import { prisma } from "@vaultledger/db";
import { supabase } from "../lib/supabase";
import { authMiddleware, AuthRequest, financeOrAdmin } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { AppError } from "../middleware/errorHandler";

export const inviteRouter = Router();

const sendInviteSchema = z.object({
  email: z.string().email(),
  role: z.enum(["ADMIN", "FINANCE", "VIEWER"]).default("VIEWER"),
});

const acceptInviteSchema = z.object({
  password: z.string().min(8),
  name: z.string().min(2).max(100),
});

inviteRouter.post(
  "/",
  authMiddleware,
  financeOrAdmin,
  validate(sendInviteSchema),
  async (req: AuthRequest, res) => {
    const { email, role } = req.body;

    const existingMember = await prisma.tenantMember.findFirst({
      where: {
        tenantId: req.user!.tenantId,
        user: { email },
      },
    });

    if (existingMember) {
      throw new AppError(409, "DUPLICATE_INVITE", "User is already a member");
    }

    const existingInvite = await prisma.invite.findFirst({
      where: {
        tenantId: req.user!.tenantId,
        email,
        status: "PENDING",
      },
    });

    if (existingInvite) {
      throw new AppError(409, "DUPLICATE_INVITE", "Invite already sent");
    }

    const token = crypto.randomBytes(32).toString("hex");

    const invite = await prisma.invite.create({
      data: {
        tenantId: req.user!.tenantId,
        email,
        role: role as "ADMIN" | "FINANCE" | "VIEWER",
        token,
        createdBy: req.user!.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    if (process.env.RESEND_API_KEY) {
      const { EmailService } = await import("../services/email");
      const emailService = new EmailService();
      await emailService.sendInviteEmail(
        email,
        "Your Company",
        role,
        `${process.env.FRONTEND_URL}/invite/${token}`
      );
    }

    res.status(201).json({ success: true, data: invite });
  }
);

inviteRouter.get(
  "/",
  authMiddleware,
  async (req: AuthRequest, res) => {
    const { status } = req.query as { status?: string };

    const invites = await prisma.invite.findMany({
      where: {
        tenantId: req.user!.tenantId,
        ...(status && { status }),
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ success: true, data: invites });
  }
);

inviteRouter.delete(
  "/:inviteId",
  authMiddleware,
  financeOrAdmin,
  async (req: AuthRequest, res) => {
    await prisma.invite.update({
      where: {
        id: req.params.inviteId,
        tenantId: req.user!.tenantId,
      },
      data: { status: "EXPIRED" },
    });

    res.json({ success: true });
  }
);

inviteRouter.post(
  "/:token/accept",
  validate(acceptInviteSchema),
  async (req, res) => {
    const { token } = req.params;
    const { password, name } = req.body;

    const invite = await prisma.invite.findUnique({
      where: { token },
      include: { tenant: true },
    });

    if (!invite) {
      throw new AppError(404, "NOT_FOUND", "Invite not found");
    }

    if (invite.status !== "PENDING") {
      throw new AppError(410, "INVITE_EXPIRED", "Invite has expired");
    }

    if (new Date() > invite.expiresAt) {
      await prisma.invite.update({
        where: { id: invite.id },
        data: { status: "EXPIRED" },
      });
      throw new AppError(410, "INVITE_EXPIRED", "Invite has expired");
    }

    const { data: authUser, error } = await supabase.auth.admin.createUser({
      email: invite.email,
      password,
      email_confirm: true,
      user_metadata: { name },
    });

    if (error || !authUser.user) {
      throw new AppError(400, "AUTH_ERROR", error?.message || "Failed to create account");
    }

    await prisma.tenantMember.create({
      data: {
        tenantId: invite.tenantId,
        userId: authUser.user.id,
        role: invite.role,
        status: "ACCEPTED",
        acceptedAt: new Date(),
      },
    });

    await prisma.invite.update({
      where: { id: invite.id },
      data: {
        status: "ACCEPTED",
        acceptedAt: new Date(),
      },
    });

    const jwt = require("jsonwebtoken");
    const accessToken = jwt.sign(
      {
        userId: authUser.user.id,
        tenantId: invite.tenantId,
        role: invite.role,
      },
      process.env.JWT_SECRET!,
      { expiresIn: "1h" }
    );

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authUser.user.id,
          email: invite.email,
          name,
        },
        tenant: invite.tenant,
        accessToken,
      },
    });
  }
);
