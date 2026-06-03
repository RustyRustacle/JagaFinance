import { Queue } from "bullmq";
import Redis from "ioredis";

let connection: Redis | null = null;

function getConnection(): Redis {
  if (!connection) {
    connection = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
      maxRetriesPerRequest: null,
      lazyConnect: true,
    });
  }
  return connection;
}

export const ocrQueue = new Queue("ocr-processing", {
  connection: getConnection(),
});

export const alertQueue = new Queue("budget-alerts", {
  connection: getConnection(),
});

export const exportQueue = new Queue("export-processing", {
  connection: getConnection(),
});

export async function enqueueOCR(receiptId: string) {
  await ocrQueue.add("process-receipt", { receiptId }, {
    attempts: 3,
    backoff: { type: "exponential", delay: 2000 },
  });
}

export async function enqueueBudgetAlert(budgetId: string) {
  await alertQueue.add("check-budget", { budgetId }, {
    attempts: 2,
    delay: 5000,
  });
}

export async function enqueueExport(exportId: string) {
  await exportQueue.add("process-export", { exportId }, {
    attempts: 2,
    backoff: { type: "fixed", delay: 3000 },
  });
}

export { startWorkers } from "./worker";
