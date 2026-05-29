"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { Search, Loader2, AlertTriangle } from "lucide-react";

interface User {
  id: string;
  email: string;
  role: string;
  status: string;
  tenant: { id: string; name: string; slug: string };
  createdAt: string;
  acceptedAt: string | null;
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;

  const fetchUsers = useCallback(() => {
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ page: String(page), limit: String(limit) });
    if (search) params.set("search", search);
    api.get(`/admin/users?${params}`)
      .then((res) => {
        const data = res.data as User[];
        setUsers(data);
        setTotal((res.meta as { total: number })?.total ?? data.length);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat pengguna"))
      .finally(() => setLoading(false));
  }, [page, search]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    fetchUsers();
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchUsers} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Pengguna</h1>
          <p className="text-sm text-gray-500 mt-1">Daftar seluruh pengguna platform</p>
        </div>
      </div>

      <form onSubmit={handleSearch} className="relative max-w-xs">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2 text-sm bg-white border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          placeholder="Cari email..." />
      </form>

      {loading ? (
        <div className="flex justify-center py-12"><Loader2 className="h-8 w-8 text-blue-600 animate-spin" /></div>
      ) : users.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-sm text-gray-400">
          {search ? "Tidak ada pengguna yang cocok" : "Belum ada pengguna"}
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Email</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Role</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Perusahaan</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Status</th>
                <th className="text-left px-5 py-3 font-medium text-gray-500">Bergabung</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-5 py-3.5 text-gray-900 font-medium">{u.email}</td>
                  <td className="px-5 py-3.5">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                      u.role === "ADMIN" ? "bg-purple-50 text-purple-700" :
                      u.role === "FINANCE" ? "bg-blue-50 text-blue-700" :
                      "bg-gray-50 text-gray-600"
                    }`}>{u.role}</span>
                  </td>
                  <td className="px-5 py-3.5 text-gray-700">{u.tenant.name}</td>
                  <td className="px-5 py-3.5">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                      u.status === "ACCEPTED" ? "bg-green-50 text-green-700" : "bg-yellow-50 text-yellow-700"
                    }`}>{u.status}</span>
                  </td>
                  <td className="px-5 py-3.5 text-gray-500 text-xs">
                    {new Date(u.createdAt).toLocaleDateString("id-ID")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="flex items-center justify-between px-5 py-3 bg-gray-50 border-t border-gray-200">
            <p className="text-xs text-gray-500">Total: {total} pengguna</p>
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
