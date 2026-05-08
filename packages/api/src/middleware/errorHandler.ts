import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { Prisma } from "@vaultledger/db";

export class AppError extends Error {
  public statusCode: number;
  public code: string;
  public details?: unknown;

  constructor(
    statusCode: number,
    code: string,
    message: string,
    details?: unknown
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  }

  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid input data",
        details: err.errors.map((e) => ({
          field: e.path.join("."),
          message: e.message,
        })),
      },
    });
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2025") {
      return res.status(404).json({
        success: false,
        error: {
          code: "NOT_FOUND",
          message: "Resource not found",
        },
      });
    }

    if (err.code === "P2002") {
      return res.status(409).json({
        success: false,
        error: {
          code: "DUPLICATE",
          message: "Resource already exists",
        },
      });
    }
  }

  console.error("Unhandled error:", err);

  return res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_ERROR",
      message: "An unexpected error occurred",
    },
  });
}
