"use client";

import { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { api } from "@/lib/api";
import { Loader2, AlertTriangle, ArrowLeft, Mail, Shield, CheckCircle, XCircle, Calendar, Building2, Receipt, Wallet } from "lucide-react";

interface UserDetail {
  id: string; email: string; role: string; status: string;
  tenant: { id: string; name: string; slug: string };
  invitedBy: string | null; invitedAt: string; acceptedAt: string | null;
  createdAt: string; updatedAt: string;
  receiptCount: number; expenseCount: number;
}

const roleColors: Record<string, string> = {
  ADMIN: "bg-purple-50 text-purple-700", FINANCE: "bg-blue-50 text-blue-700", VIEWER: "bg-gray-50 text-gray-600",
};

const statusColors: Record<string, string> = {
  ACCEPTED: "bg-green-50 text-green-700", PENDING: "bg-yellow-50 text-yellow-700",
  EXPIRED: "bg-red-50 text-red-700", DECLINED: "bg-gray-100 text-gray-500",
};

export default function AdminUserDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [user, setUser] = useState<UserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUser = useCallback(() => {
    setLoading(true); setError(null);
    api.get(`/admin/users/${params.id}`)
      .then((res) => setUser(res.data as UserDetail))
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat detail pengguna"))
      .finally(() => setLoading(false));
  }, [params.id]);

  useEffect(() => { fetchUser(); }, [fetchUser]);

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchUser} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  if (loading) return <div className="flex items-center justify-center min-h-[60vh]"><Loader2 className="h-8 w-8 text-blue-600 animate-spin" /></div>;
  if (!user) return null;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button onClick={() => router.back()}
          className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Detail Pengguna</h1>
          <p className="text-sm text-gray-500 mt-0.5">{user.email}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Informasi Akun</h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoRow icon={Mail} label="Email" value={user.email} />
              <InfoRow icon={Shield} label="Role" value={user.role} badge={roleColors[user.role]} />
              <InfoRow icon={CheckCircle} label="Status" value={user.status} badge={statusColors[user.status]} />
              <InfoRow icon={Calendar} label="Bergabung" value={new Date(user.createdAt).toLocaleDateString("id-ID", { year: "numeric", month: "long", day: "numeric" })} />
              {user.acceptedAt && (
                <InfoRow icon={CheckCircle} label="Diterima" value={new Date(user.acceptedAt).toLocaleDateString("id-ID", { year: "numeric", month: "long", day: "numeric" })} />
              )}
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Aktivitas</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center gap-3 p-4 rounded-lg bg-blue-50">
                <Receipt className="h-5 w-5 text-blue-600" />
                <div>
                  <p className="text-2xl font-bold text-gray-900">{user.receiptCount}</p>
                  <p className="text-xs text-gray-500">Struk diupload</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-4 rounded-lg bg-orange-50">
                <Wallet className="h-5 w-5 text-orange-600" />
                <div>
                  <p className="text-2xl font-bold text-gray-900">{user.expenseCount}</p>
                  <p className="text-xs text-gray-500">Pengeluaran</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Perusahaan</h3>
            <Link href={`/admin/tenants`}
              className="flex items-center gap-3 p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors">
              <div className="h-10 w-10 rounded-lg bg-indigo-50 flex items-center justify-center">
                <Building2 className="h-5 w-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">{user.tenant.name}</p>
                <p className="text-xs text-gray-500">{user.tenant.slug}</p>
              </div>
            </Link>
          </div>

          {user.invitedBy && (
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-2">Diundang oleh</h3>
              <p className="text-sm text-gray-700">{user.invitedBy}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoRow({ icon: Icon, label, value, badge }: { icon: React.ElementType; label: string; value: string; badge?: string }) {
  return (
    <div className="flex items-start gap-3">
      <div className="h-8 w-8 rounded-lg bg-gray-50 flex items-center justify-center shrink-0 mt-0.5">
        <Icon className="h-4 w-4 text-gray-500" />
      </div>
      <div className="min-w-0">
        <p className="text-xs text-gray-500 mb-0.5">{label}</p>
        {badge ? (
          <span className={`inline-block text-xs font-medium px-2 py-0.5 rounded-full ${badge}`}>{value}</span>
        ) : (
          <p className="text-sm font-medium text-gray-900 break-all">{value}</p>
        )}
      </div>
    </div>
  );
}
