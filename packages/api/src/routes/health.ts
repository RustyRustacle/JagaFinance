import { Router } from "express";
import { prisma } from "@vaultledger/db";

export const healthRouter = Router();

healthRouter.get("/", async (_req, res) => {
  const health = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    services: {
      database: "unknown",
      redis: "unknown",
      storage: "unknown",
    },
  };

  try {
    await prisma.$queryRaw`SELECT 1`;
    health.services.database = "connected";
  } catch {
    health.services.database = "disconnected";
    health.status = "degraded";
  }

  try {
    const Redis = require("ioredis");
    const redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379");
    await redis.ping();
    health.services.redis = "connected";
    await redis.quit();
  } catch {
    health.services.redis = "disconnected";
    health.status = "degraded";
  }

  health.services.storage =
    process.env.SUPABASE_URL ? "connected" : "not_configured";

  res.status(health.status === "healthy" ? 200 : 503).json(health);
});
