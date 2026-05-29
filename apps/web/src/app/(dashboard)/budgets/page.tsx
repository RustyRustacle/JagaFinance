"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { formatIDR } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Target, Plus, AlertTriangle, Pencil, Trash2, X } from "lucide-react";

interface Category {
  id: string;
  name: string;
  color: string;
}

interface Budget {
  id: string;
  categoryId: string;
  amount: number;
  currency: string;
  period: string;
  startDate: string;
  endDate: string;
  alertThreshold: number;
  isActive: boolean;
  category: Category;
}

interface BudgetForm {
  category_id: string;
  amount: string;
  period: string;
  start_date: string;
  end_date: string;
  alert_threshold: string;
}

function emptyForm(): BudgetForm {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split("T")[0];
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split("T")[0];
  return { category_id: "", amount: "", period: "MONTHLY", start_date: start, end_date: end, alert_threshold: "80" };
}

export default function BudgetsPage() {
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<BudgetForm>(emptyForm());
  const [saving, setSaving] = useState(false);

  const fetchBudgets = useCallback(() => {
    setLoading(true);
    setError(null);
    Promise.all([
      api.get("/budgets"),
      api.get("/categories"),
    ]).then(([bRes, cRes]) => {
      setBudgets(bRes.data as Budget[]);
      setCategories(cRes.data as Category[]);
    }).catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat anggaran"))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchBudgets(); }, [fetchBudgets]);

  function openCreate() {
    setForm(emptyForm());
    setEditingId(null);
    setShowModal(true);
  }

  function openEdit(b: Budget) {
    setForm({
      category_id: b.categoryId,
      amount: String(b.amount),
      period: b.period,
      start_date: b.startDate.split("T")[0],
      end_date: b.endDate.split("T")[0],
      alert_threshold: String(b.alertThreshold),
    });
    setEditingId(b.id);
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.category_id || !form.amount) return;
    setSaving(true);
    try {
      const body = {
        category_id: form.category_id,
        amount: Number(form.amount),
        period: form.period,
        start_date: form.start_date,
        end_date: form.end_date,
        alert_threshold: Number(form.alert_threshold),
      };
      if (editingId) {
        await api.patch(`/budgets/${editingId}`, body);
      } else {
        await api.post("/budgets", body);
      }
      setShowModal(false);
      await fetchBudgets();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan anggaran");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string) {
    if (!window.confirm("Hapus anggaran ini?")) return;
    try {
      await api.delete(`/budgets/${id}`);
      await fetchBudgets();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menghapus anggaran");
    }
  }

  function periodLabel(p: string) {
    const map: Record<string, string> = { MONTHLY: "Bulanan", QUARTERLY: "Kuartalan", YEARLY: "Tahunan" };
    return map[p] || p;
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchBudgets} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Anggaran</h1>
          <p className="text-gray-600 dark:text-gray-400">Tetapkan dan pantau batas pengeluaran</p>
        </div>
        <button onClick={openCreate} className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg">
          <Plus className="h-4 w-4" /> Tambah Anggaran
        </button>
      </div>

      {loading ? (
        <div className="animate-pulse space-y-4">
          {[1, 2].map((i) => <div key={i} className="h-28 bg-gray-200 dark:bg-gray-700 rounded-xl" />)}
        </div>
      ) : budgets.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            <Target className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>Belum ada anggaran</p>
            <button onClick={openCreate} className="mt-4 text-sm text-blue-600 hover:underline">Buat anggaran pertama</button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {budgets.map((b) => (
            <Card key={b.id}>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: b.category?.color || "#6B7280" }} />
                    <CardTitle className="text-base">{b.category?.name || "Kategori"}</CardTitle>
                  </div>
                  <div className="flex gap-1">
                    <button onClick={() => openEdit(b)} className="p-1.5 text-gray-400 hover:text-blue-600 rounded"><Pencil className="h-3.5 w-3.5" /></button>
                    <button onClick={() => handleDelete(b.id)} className="p-1.5 text-gray-400 hover:text-red-600 rounded"><Trash2 className="h-3.5 w-3.5" /></button>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="flex justify-between mb-2">
                  <span className="text-sm text-gray-500">{periodLabel(b.period)}</span>
                  <span className="text-sm font-medium">{formatIDR(b.amount)}</span>
                </div>
                <p className="text-xs text-gray-400">
                  {new Date(b.startDate).toLocaleDateString("id-ID")} — {new Date(b.endDate).toLocaleDateString("id-ID")}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setShowModal(false)}>
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md mx-4 p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold">{editingId ? "Edit Anggaran" : "Tambah Anggaran"}</h2>
              <button onClick={() => setShowModal(false)} className="p-1 text-gray-400 hover:text-gray-600"><X className="h-5 w-5" /></button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Kategori</label>
                <select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800">
                  <option value="">Pilih kategori</option>
                  {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Jumlah (Rp)</label>
                <input type="number" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" placeholder="1000000" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Periode</label>
                <select value={form.period} onChange={(e) => setForm({ ...form, period: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800">
                  <option value="MONTHLY">Bulanan</option>
                  <option value="QUARTERLY">Kuartalan</option>
                  <option value="YEARLY">Tahunan</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium mb-1">Mulai</label>
                  <input type="date" value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Selesai</label>
                  <input type="date" value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Batas Peringatan ({form.alert_threshold}%)</label>
                <input type="range" min="0" max="100" value={form.alert_threshold} onChange={(e) => setForm({ ...form, alert_threshold: e.target.value })} className="w-full" />
              </div>
              <button onClick={handleSave} disabled={saving || !form.category_id || !form.amount} className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-medium rounded-lg text-sm">
                {saving ? "Menyimpan..." : editingId ? "Simpan Perubahan" : "Buat Anggaran"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
