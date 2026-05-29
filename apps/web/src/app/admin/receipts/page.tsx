"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import { Search, Loader2, AlertTriangle, ExternalLink } from "lucide-react";

interface ReceiptRow {
  id: string;
  fileName: string;
  fileType: string;
  status: string;
  totalAmount: number | null;
  uploaderEmail: string;
  tenantName: string;
  createdAt: string;
}

const statusColors: Record<string, string> = {
  UPLOADED: "bg-gray-50 text-gray-600",
  PROCESSING: "bg-blue-50 text-blue-700",
  COMPLETED: "bg-green-50 text-green-700",
  FINALIZED: "bg-purple-50 text-purple-700",
  FAILED: "bg-red-50 text-red-700",
  REJECTED: "bg-orange-50 text-orange-700",
};

export default function AdminReceiptsPage() {
  const [receipts, setReceipts] = useState<ReceiptRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;

  const fetchReceipts = useCallback(() => {
    setLoading(true); setError(null);
    const params = new URLSearchParams({ page: String(page), limit: String(limit) });
    if (search) params.set("search", search);
    api.get(`/admin/receipts?${params}`)
      .then((res) => {
        const data = res.data as ReceiptRow[];
        setReceipts(data);
        setTotal((res.meta as { total: number })?.total ?? data.length);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat struk"))
      .finally(() => setLoading(false));
  }, [page, search]);

  useEffect(() => { fetchReceipts(); }, [fetchReceipts]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    fetchReceipts();
  }

  function fmtIDR(n: number) {
    return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(n);
  }

  function fmtDate(d: string) {
    return new Date(d).toLocaleDateString("id-ID");
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchReceipts} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Struk</h1>
          <p className="text-sm text-gray-500 mt-1">Daftar seluruh struk yang diupload</p>
        </div>
      </div>

      <form onSubmit={handleSearch} className="relative max-w-xs">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2 text-sm bg-white border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          placeholder="Cari nama file..." />
      </form>

      {loading ? (
        <div className="flex justify-center py-12"><Loader2 className="h-8 w-8 text-blue-600 animate-spin" /></div>
      ) : receipts.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-sm text-gray-400">
          {search ? "Tidak ada struk yang cocok" : "Belum ada struk"}
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-5 py-3 font-medium text-gray-500">File</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Perusahaan</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Uploader</th>
                <th className="text-right px-5 py-3 font-medium text-gray-500">Nilai</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Status</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Tanggal</th>
                <th className="text-center px-5 py-3 font-medium text-gray-500"></th>
              </tr>
            </thead>
            <tbody>
              {receipts.map((r) => (
                <tr key={r.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-5 py-3.5">
                    <p className="font-medium text-gray-900 truncate max-w-[200px]">{r.fileName}</p>
                    <p className="text-xs text-gray-400">{r.fileType}</p>
                  </td>
                  <td className="px-5 py-3.5 text-gray-700">{r.tenantName}</td>
                  <td className="px-5 py-3.5 text-gray-500 text-xs">{r.uploaderEmail}</td>
                  <td className="px-5 py-3.5 text-right font-medium text-gray-900">
                    {r.totalAmount != null ? fmtIDR(r.totalAmount) : "-"}
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusColors[r.status] || "bg-gray-50 text-gray-600"}`}>
                      {r.status}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 text-gray-500 text-xs">{fmtDate(r.createdAt)}</td>
                  <td className="px-5 py-3.5 text-center">
                    <Link href={`/admin/receipts/${r.id}`}
                      className="inline-flex items-center gap-1 text-xs font-medium text-blue-600 hover:text-blue-700">
                      Detail <ExternalLink className="h-3 w-3" />
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="flex items-center justify-between px-5 py-3 bg-gray-50 border-t border-gray-200">
            <p className="text-xs text-gray-500">Total: {total} struk</p>
            <div className="flex gap-2">
              <button disabled={page <= 1} onClick={() => setPage(page - 1)}
                className="px-3 py-1.5 text-xs font-medium bg-white border border-gray-200 rounded-lg hover:bg-gray-50 disabled:opacity-50">Sebelumnya</button>
              <button disabled={page * limit >= total} onClick={() => setPage(page + 1)}
                className="px-3 py-1.5 text-xs font-medium bg-white border border-gray-200 rounded-lg hover:bg-gray-50 disabled:opacity-50">Selanjutnya</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
