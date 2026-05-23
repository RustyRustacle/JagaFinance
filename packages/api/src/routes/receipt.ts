import { Router } from "express";
import multer from "multer";
import { z } from "zod";
import path from "path";
import { prisma, ReceiptStatus } from "@jagafinance/db";
import type { Prisma } from "@jagafinance/db";
import { supabase } from "../lib/supabase";
import { authMiddleware, AuthRequest, financeOrAdmin, adminOnly } from "../middleware/auth";
import { AppError } from "../middleware/errorHandler";
import { validate } from "../middleware/validate";
import { enqueueOCR } from "../lib/queue";
import { submitReceiptToBlockchain } from "../services/blockchain";
import { createAuditLog } from "../lib/audit";

export const receiptRouter = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_req, file, cb) => {
    const allowed = ["image/jpeg", "image/png", "image/webp", "application/pdf"];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Only JPG, PNG, WebP, and PDF files are allowed"));
    }
  },
});

const reviewSchema = z.object({
  action: z.enum(["approve", "reject", "edit"]),
  corrections: z
    .object({
      merchant_name: z.string().optional(),
      total_amount: z.number().optional(),
      transaction_date: z.string().optional(),
      tax_amount: z.number().optional(),
      tax_rate: z.number().optional(),
    })
    .optional(),
  notes: z.string().optional(),
});

const listQuerySchema = z.object({
  status: z.string().optional(),
  category_id: z.string().uuid().optional(),
  date_from: z.string().optional(),
  date_to: z.string().optional(),
  merchant_name: z.string().optional(),
  sort: z.string().default("created_at"),
  order: z.enum(["asc", "desc"]).default("desc"),
  page: z.coerce.number().default(1),
  limit: z.coerce.number().default(20),
});

receiptRouter.use(authMiddleware);

receiptRouter.post(
  "/upload",
  financeOrAdmin,
  upload.single("file"),
  async (req: AuthRequest, res) => {
    const file = req.file;
    if (!file) {
      throw new AppError(400, "VALIDATION_ERROR", "No file uploaded");
    }

    const fileExt = path.extname(file.originalname);
    const fileName = `${req.user!.tenantId}/${Date.now()}-${file.originalname}`;

    const { data, error } = await supabase.storage
      .from("receipts")
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
      });

    if (error) {
      throw new AppError(500, "UPLOAD_ERROR", error.message);
    }

    const { data: urlData } = supabase.storage
      .from("receipts")
      .getPublicUrl(data.path);

    const receipt = await prisma.receipt.create({
      data: {
        tenantId: req.user!.tenantId,
        uploadedBy: req.user!.id,
        fileUrl: urlData.publicUrl,
        fileName: file.originalname,
        fileType: file.mimetype,
        fileSize: file.size,
        status: "UPLOADED",
      },
    });

    await enqueueOCR(receipt.id);

    res.status(201).json({
      success: true,
      data: receipt,
    });

    createAuditLog({
      tenantId: req.user!.tenantId,
      userId: req.user!.id,
      action: "CREATE",
      entityType: "Receipt",
      entityId: receipt.id,
      changes: { fileName: file.originalname, fileSize: file.size },
      req,
    });
  }
);

receiptRouter.get("/", async (req: AuthRequest, res) => {
  const parsed = listQuerySchema.safeParse(req.query);
  const query = parsed.success ? parsed.data : { page: 1, limit: 20, sort: "created_at", order: "desc" as const };

  const where: Prisma.ReceiptWhereInput = {
    tenantId: req.user!.tenantId,
  };

  const qStatus = "status" in query ? query.status : undefined;
  const qDateFrom = "date_from" in query ? query.date_from : undefined;
  const qDateTo = "date_to" in query ? query.date_to : undefined;

  if (qStatus) where.status = qStatus as ReceiptStatus;
  if (qDateFrom || qDateTo) {
    where.createdAt = {};
    if (qDateFrom) where.createdAt.gte = new Date(qDateFrom);
    if (qDateTo) where.createdAt.lte = new Date(qDateTo);
  }

  const [receipts, total] = await Promise.all([
    prisma.receipt.findMany({
      where,
      include: {
        receiptData: true,
        uploader: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: { [query.sort]: query.order },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    }),
    prisma.receipt.count({ where }),
  ]);

  res.json({
    success: true,
    data: receipts,
    meta: {
      page: query.page,
      limit: query.limit,
      total,
      totalPages: Math.ceil(total / query.limit),
    },
  });
});

receiptRouter.get("/:id", async (req: AuthRequest, res) => {
  const receipt = await prisma.receipt.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
    include: {
      receiptData: true,
      uploader: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });

  if (!receipt) {
    throw new AppError(404, "NOT_FOUND", "Receipt not found");
  }

  res.json({ success: true, data: receipt });
});

receiptRouter.post(
  "/:id/review",
  financeOrAdmin,
  validate(reviewSchema),
  async (req: AuthRequest, res) => {
    const receipt = await prisma.receipt.findFirst({
      where: {
        id: req.params.id,
        tenantId: req.user!.tenantId,
      },
      include: { receiptData: true },
    });

    if (!receipt) {
      throw new AppError(404, "NOT_FOUND", "Receipt not found");
    }

    const { action, corrections, notes } = req.body;

    if (action === "approve") {
      await prisma.receipt.update({
        where: { id: req.params.id },
        data: { status: "COMPLETED" },
      });

      const receiptData = await prisma.receipt.findUnique({
        where: { id: req.params.id },
        include: { receiptData: true },
      });

      if (receiptData?.receiptData) {
        const bcResult = await submitReceiptToBlockchain(
          receiptData.id,
          receiptData.tenantId,
          receiptData.receiptData.totalAmount.toString(),
          receiptData.createdAt.toISOString()
        );

        if (bcResult.status === "CONFIRMED") {
          await prisma.receipt.update({
            where: { id: req.params.id },
            data: {
              status: "FINALIZED",
              blockchainTxHash: bcResult.txHash,
              blockchainStatus: "CONFIRMED",
              blockchainNetwork: process.env.BLOCKCHAIN_CHAIN_ID === "84532" ? "base_sepolia" : "base",
              blockchainSubmittedAt: new Date(),
              blockchainConfirmedAt: new Date(),
            },
          });
        } else {
          await prisma.receipt.update({
            where: { id: req.params.id },
            data: {
              blockchainStatus: "FAILED",
              blockchainSubmittedAt: new Date(),
            },
          });
        }
      }
    } else if (action === "reject") {
      await prisma.receipt.update({
        where: { id: req.params.id },
        data: {
          status: "REJECTED",
          errorMessage: notes,
        },
      });
    } else if (action === "edit" && corrections) {
      const updateData: Record<string, unknown> = {
        ...corrections,
        isVerified: true,
        verifiedBy: req.user!.id,
        verificationNotes: notes,
      };

      if (corrections.transaction_date) {
        updateData.transactionDate = new Date(corrections.transaction_date);
      }

      if (receipt.receiptData) {
        await prisma.receiptData.update({
          where: { receiptId: req.params.id },
          data: updateData,
        });
      } else if (corrections.total_amount != null) {
        await prisma.receiptData.create({
          data: {
            receiptId: req.params.id,
            ...updateData,
            totalAmount: corrections.total_amount,
          },
        });
      } else {
        throw new AppError(400, "VALIDATION_ERROR", "total_amount is required when creating receipt data");
      }
    }

    res.json({ success: true });

    createAuditLog({
      tenantId: req.user!.tenantId,
      userId: req.user!.id,
      action: "UPDATE",
      entityType: "Receipt",
      entityId: req.params.id,
      changes: { action, corrections, notes },
      req,
    });
  }
);

receiptRouter.delete("/:id", adminOnly, async (req: AuthRequest, res) => {
  const receipt = await prisma.receipt.findFirst({
    where: {
      id: req.params.id,
      tenantId: req.user!.tenantId,
    },
  });

  if (!receipt) {
    throw new AppError(404, "NOT_FOUND", "Receipt not found");
  }

  const fileName = receipt.fileUrl.split("/").slice(-2).join("/");
  await supabase.storage.from("receipts").remove([fileName]);

  await prisma.receipt.delete({
    where: { id: req.params.id },
  });

  res.json({ success: true });

  createAuditLog({
    tenantId: req.user!.tenantId,
    userId: req.user!.id,
    action: "DELETE",
    entityType: "Receipt",
    entityId: req.params.id,
    req,
  });
});
