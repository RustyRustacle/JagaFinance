"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { formatIDR, formatDate } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plus, Wallet, AlertTriangle, X, Loader2 } from "lucide-react";

interface Expense {
  id: string;
  title: string;
  amount: number;
  expenseDate: string;
  category: { id: string; name: string } | null;
  status: string;
}

interface Category {
  id: string;
  name: string;
}

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ category_id: "", title: "", amount: "", expense_date: new Date().toISOString().split("T")[0], description: "" });

  const fetchExpenses = useCallback(() => {
    setLoading(true);
    setError(null);
    api.get("/expenses")
      .then((res) => setExpenses(res.data as Expense[]))
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat pengeluaran"))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchExpenses();
    api.get("/categories").then((res) => setCategories(res.data as Category[])).catch(() => {});
  }, [fetchExpenses]);

  function openCreate() {
    setForm({ category_id: "", title: "", amount: "", expense_date: new Date().toISOString().split("T")[0], description: "" });
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.title || !form.amount || !form.category_id) return;
    setSaving(true);
    try {
      await api.post("/expenses", {
        category_id: form.category_id,
        title: form.title,
        amount: Number(form.amount),
        expense_date: form.expense_date,
        description: form.description || undefined,
      });
      setShowModal(false);
      await fetchExpenses();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan pengeluaran");
    } finally {
      setSaving(false);
    }
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchExpenses} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  if (loading) return <div className="animate-pulse">Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Pengeluaran</h1>
          <p className="text-gray-600 dark:text-gray-400">Catat dan kelola pengeluaran Anda</p>
        </div>
        <button onClick={openCreate} className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg">
          <Plus className="h-4 w-4" /> Tambah Pengeluaran
        </button>
      </div>

      <Card>
        <CardHeader><CardTitle>Riwayat Pengeluaran</CardTitle></CardHeader>
        <CardContent>
          {expenses.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Wallet className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Belum ada pengeluaran</p>
              <button onClick={openCreate} className="mt-4 text-sm text-blue-600 hover:underline">Catat pengeluaran pertama</button>
            </div>
          ) : (
            <div className="space-y-3">
              {expenses.map((exp) => (
                <div key={exp.id} className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900 dark:text-white">{exp.title}</p>
                    <p className="text-xs text-gray-500">{exp.category?.name || "-"} &middot; {formatDate(exp.expenseDate)}</p>
                  </div>
                  <span className="font-medium text-gray-900 dark:text-white">{formatIDR(Number(exp.amount))}</span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setShowModal(false)}>
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md mx-4 p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold">Tambah Pengeluaran</h2>
              <button onClick={() => setShowModal(false)} className="p-1 text-gray-400 hover:text-gray-600"><X className="h-5 w-5" /></button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Judul</label>
                <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" placeholder="Belanja Bulanan" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Kategori</label>
                <select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800">
                  <option value="">Pilih kategori</option>
                  {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Jumlah (Rp)</label>
                <input type="number" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" placeholder="500000" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Tanggal</label>
                <input type="date" value={form.expense_date} onChange={(e) => setForm({ ...form, expense_date: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Deskripsi (opsional)</label>
                <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" rows={2} placeholder="Catatan tambahan" />
              </div>
              <button onClick={handleSave} disabled={saving || !form.title || !form.amount || !form.category_id} className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-medium rounded-lg text-sm">
                {saving ? "Menyimpan..." : "Simpan"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
