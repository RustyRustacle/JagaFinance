import "express-async-errors";
import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { healthRouter } from "./routes/health";
import { authRouter } from "./routes/auth";
import { tenantRouter } from "./routes/tenant";
import { inviteRouter } from "./routes/invite";
import { receiptRouter } from "./routes/receipt";
import { expenseRouter } from "./routes/expense";
import { categoryRouter } from "./routes/category";
import { budgetRouter } from "./routes/budget";
import { dashboardRouter } from "./routes/dashboard";
import { exportRouter } from "./routes/export";
import { adminRouter } from "./routes/admin";
import { errorHandler } from "./middleware/errorHandler";
import { startWorkers } from "./lib/queue";

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    credentials: true,
  })
);
app.use(morgan("dev"));
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many requests, please try again later.",
    },
  },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many auth attempts, please try again later.",
    },
  },
});

const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many uploads, please try again later.",
    },
  },
});

app.use("/api/v1/", generalLimiter);
app.use("/api/v1/auth", authLimiter);
app.use("/api/v1/receipts/upload", uploadLimiter);

app.use("/api/v1/health", healthRouter);
app.use("/api/v1/auth", authRouter);
app.use("/api/v1/tenants", tenantRouter);
app.use("/api/v1/invites", inviteRouter);
app.use("/api/v1/receipts", receiptRouter);
app.use("/api/v1/expenses", expenseRouter);
app.use("/api/v1/categories", categoryRouter);
app.use("/api/v1/budgets", budgetRouter);
app.use("/api/v1/dashboard", dashboardRouter);
app.use("/api/v1/exports", exportRouter);
app.use("/api/v1/admin", adminRouter);

app.use(errorHandler);

app.listen(PORT, async () => {
  console.log(`JagaFinance API running on http://localhost:${PORT}`);

  if (process.env.REDIS_URL) {
    try {
      await startWorkers();
    } catch (err) {
      console.warn("Queue workers failed to start (Redis may not be running):", err);
    }
  }
});

export { app };
