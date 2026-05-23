"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { formatIDR, formatDate } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ReceiptUpload } from "@/components/receipt-upload";
import { RefreshCw, FileText, Filter, Download } from "lucide-react";

interface Receipt {
  id: string;
  fileName: string;
  fileUrl: string;
  status: string;
  createdAt: string;
  ocrConfidence: number | null;
  receiptData?: {
    merchantName: string | null;
    totalAmount: string | null;
    transactionDate: string | null;
  };
}

export default function ReceiptsPage() {
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>("all");

  const fetchReceipts = useCallback(() => {
    const query = filter !== "all" ? `?status=${filter}` : "";
    api.get(`/receipts${query}`)
      .then((res) => setReceipts(res.data.data ?? []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [filter]);

  useEffect(() => {
    fetchReceipts();
  }, [fetchReceipts]);

  const statusColors: Record<string, string> = {
    UPLOADED: "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300",
    PROCESSING: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
    COMPLETED: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
    FINALIZED: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
    FAILED: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
    REJECTED: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  };

  if (loading) return <div className="animate-pulse space-y-4"><div className="h-8 w-48 bg-gray-200 dark:bg-gray-700 rounded" /><div className="h-40 bg-gray-200 dark:bg-gray-700 rounded-xl" /></div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Receipts</h1>
        <p className="text-gray-600 dark:text-gray-400">Upload and manage your receipts</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Upload Receipts</CardTitle>
        </CardHeader>
        <CardContent>
          <ReceiptUpload />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <div>
            <CardTitle>Recent Receipts</CardTitle>
            <p className="text-sm text-gray-500 mt-1">{receipts.length} receipt{receipts.length !== 1 ? "s" : ""}</p>
          </div>
          <div className="flex items-center gap-2">
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1.5 bg-white dark:bg-gray-800"
            >
              <option value="all">All Status</option>
              <option value="COMPLETED">Completed</option>
              <option value="FINALIZED">Finalized</option>
              <option value="PROCESSING">Processing</option>
              <option value="UPLOADED">Uploaded</option>
              <option value="FAILED">Failed</option>
            </select>
            <button onClick={fetchReceipts} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
              <RefreshCw className="h-4 w-4" />
            </button>
            <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
              <Download className="h-4 w-4" />
            </button>
          </div>
        </CardHeader>
        <CardContent>
          {receipts.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <FileText className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No receipts yet. Upload one above!</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700">
                    <th className="text-left py-3 px-4 text-gray-500 font-medium">Receipt</th>
                    <th className="text-left py-3 px-4 text-gray-500 font-medium">Merchant</th>
                    <th className="text-left py-3 px-4 text-gray-500 font-medium">Date</th>
                    <th className="text-right py-3 px-4 text-gray-500 font-medium">Amount</th>
                    <th className="text-center py-3 px-4 text-gray-500 font-medium">Status</th>
                    <th className="text-center py-3 px-4 text-gray-500 font-medium">Confidence</th>
                  </tr>
                </thead>
                <tbody>
                  {receipts.map((r) => (
                    <tr key={r.id} className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div className="h-8 w-8 rounded bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
                            <FileText className="h-4 w-4 text-gray-400" />
                          </div>
                          <span className="font-medium text-gray-900 dark:text-white truncate max-w-32">{r.fileName}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-gray-700 dark:text-gray-300">{r.receiptData?.merchantName || "-"}</td>
                      <td className="py-3 px-4 text-gray-500">{r.receiptData?.transactionDate ? formatDate(r.receiptData.transactionDate) : formatDate(r.createdAt)}</td>
                      <td className="py-3 px-4 text-right font-medium text-gray-900 dark:text-white">{r.receiptData?.totalAmount ? formatIDR(Number(r.receiptData.totalAmount)) : "-"}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${statusColors[r.status]}`}>
                          {r.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-center">
                        {r.ocrConfidence != null ? (
                          <span className={`text-xs ${r.ocrConfidence >= 0.8 ? "text-green-600" : r.ocrConfidence >= 0.5 ? "text-yellow-600" : "text-red-600"}`}>
                            {(r.ocrConfidence * 100).toFixed(0)}%
                          </span>
                        ) : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
