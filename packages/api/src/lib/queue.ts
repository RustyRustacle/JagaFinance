import { Queue } from "bullmq";
import Redis from "ioredis";

let connection: Redis | null = null;

function getConnection(): Redis {
  if (!connection) {
    connection = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
      maxRetriesPerRequest: null,
      lazyConnect: true,
      enableOfflineQueue: false,
    });
  }
  return connection;
}

function getQueue(name: string): Queue {
  return new Queue(name, { connection: getConnection() });
}

function getOcrQueue(): Queue {
  return getQueue("ocr-processing");
}

function getAlertQueue(): Queue {
  return getQueue("budget-alerts");
}

function getExportQueue(): Queue {
  return getQueue("export-processing");
}

export async function enqueueOCR(receiptId: string) {
  await getOcrQueue().add("process-receipt", { receiptId }, {
    attempts: 3,
    backoff: { type: "exponential", delay: 2000 },
  });
}

export async function enqueueBudgetAlert(budgetId: string) {
  await getAlertQueue().add("check-budget", { budgetId }, {
    attempts: 2,
    delay: 5000,
  });
}

export async function enqueueExport(exportId: string) {
  await getExportQueue().add("process-export", { exportId }, {
    attempts: 2,
    backoff: { type: "fixed", delay: 3000 },
  });
}

export { startWorkers } from "./worker";
