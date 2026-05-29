"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { Users, Building2, Receipt, Wallet, Loader2, TrendingUp, AlertTriangle } from "lucide-react";

interface AdminStats {
  counts: { tenants: number; members: number; receipts: number; expenses: number; budgets: number };
  totals: { receiptAmount: number; expenseAmount: number };
  receiptStatuses: Record<string, number>;
  expenseStatuses: Record<string, number>;
  monthlyTrend: Array<{ month: string; count: number; total: number }>;
  recentTenants: Array<{ id: string; name: string; slug: string; createdAt: string }>;
  recentMembers: Array<{ userId: string; tenantName: string; role: string; createdAt: string }>;
}

export default function AdminDashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = useCallback(() => {
    setLoading(true);
    setError(null);
    api.get("/admin/stats")
      .then((res) => setStats(res.data as AdminStats))
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat statistik"))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchStats(); }, [fetchStats]);

  function fmt(n: number) { return new Intl.NumberFormat("id-ID").format(n); }
  function fmtIDR(n: number) {
    return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(n);
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchStats} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  if (loading) return <div className="flex items-center justify-center min-h-[60vh]"><Loader2 className="h-8 w-8 text-blue-600 animate-spin" /></div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard Admin</h1>
        <p className="text-sm text-gray-500 mt-1">Ringkasan seluruh platform JagaFinance</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard icon={Building2} label="Perusahaan" value={fmt(stats!.counts.tenants)} color="blue" />
        <StatCard icon={Users} label="Anggota" value={fmt(stats!.counts.members)} color="indigo" />
        <StatCard icon={Receipt} label="Struk" value={fmt(stats!.counts.receipts)} color="green" />
        <StatCard icon={Wallet} label="Pengeluaran" value={fmt(stats!.counts.expenses)} color="orange" />
        <StatCard icon={TrendingUp} label="Anggaran" value={fmt(stats!.counts.budgets)} color="purple" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Total Nilai</h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Total Nilai Struk</span>
              <span className="text-lg font-bold text-gray-900">{fmtIDR(Number(stats!.totals.receiptAmount))}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Total Pengeluaran</span>
              <span className="text-lg font-bold text-gray-900">{fmtIDR(Number(stats!.totals.expenseAmount))}</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Status Struk</h3>
          <div className="space-y-3">
            {Object.entries(stats!.receiptStatuses).map(([status, count]) => (
              <div key={status} className="flex justify-between items-center">
                <span className="text-sm text-gray-600">{status}</span>
                <span className="text-sm font-semibold text-gray-900">{fmt(count)}</span>
              </div>
            ))}
            {Object.keys(stats!.receiptStatuses).length === 0 && (
              <p className="text-sm text-gray-400">Belum ada data</p>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Aktivitas Terbaru</h3>
          <div className="space-y-3">
            {stats!.recentMembers.slice(0, 8).map((m, i) => (
              <div key={`${m.userId}-${i}`} className="flex justify-between items-center">
                <div>
                  <p className="text-sm font-medium text-gray-900">{m.userId.slice(0, 8)}...</p>
                  <p className="text-xs text-gray-400">{m.tenantName}</p>
                </div>
                <span className="text-xs text-gray-400">
                  {new Date(m.createdAt).toLocaleDateString("id-ID")}
                </span>
              </div>
            ))}
            {stats!.recentMembers.length === 0 && (
              <p className="text-sm text-gray-400">Belum ada aktivitas</p>
            )}
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Perusahaan Baru</h3>
          <div className="space-y-3">
            {stats!.recentTenants.map((t) => (
              <div key={t.id} className="flex justify-between items-center">
                <div>
                  <p className="text-sm font-medium text-gray-900">{t.name}</p>
                  <p className="text-xs text-gray-400">{t.slug}</p>
                </div>
                <span className="text-xs text-gray-400">
                  {new Date(t.createdAt).toLocaleDateString("id-ID")}
                </span>
              </div>
            ))}
            {stats!.recentTenants.length === 0 && (
              <p className="text-sm text-gray-400">Belum ada perusahaan</p>
            )}
          </div>
        </div>
      </div>

      {stats!.monthlyTrend.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Tren Bulanan (12 bulan)</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-400 border-b border-gray-100">
                  <th className="pb-2 font-medium">Bulan</th>
                  <th className="pb-2 font-medium">Jumlah Struk</th>
                  <th className="pb-2 font-medium">Total Nilai</th>
                </tr>
              </thead>
              <tbody>
                {stats!.monthlyTrend.map((row) => {
                  const [year, month] = row.month.split("-");
                  const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
                  const label = `${monthNames[parseInt(month)]} ${year}`;
                  return (
                    <tr key={row.month} className="border-b border-gray-50">
                      <td className="py-2.5 text-gray-900 font-medium">{label}</td>
                      <td className="py-2.5 text-gray-700">{fmt(row.count)}</td>
                      <td className="py-2.5 text-gray-700">{fmtIDR(row.total)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType; label: string; value: string; color: string }) {
  const colors: Record<string, string> = {
    blue: "bg-blue-50 text-blue-600",
    indigo: "bg-indigo-50 text-indigo-600",
    green: "bg-green-50 text-green-600",
    orange: "bg-orange-50 text-orange-600",
    purple: "bg-purple-50 text-purple-600",
  };
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-center gap-3">
        <div className={`h-10 w-10 rounded-lg ${colors[color]} flex items-center justify-center`}>
          <Icon className="h-5 w-5" />
        </div>
        <div>
          <p className="text-xs text-gray-500">{label}</p>
          <p className="text-lg font-bold text-gray-900">{value}</p>
        </div>
      </div>
    </div>
  );
}
