"use client";

import { useState, useEffect, useCallback } from "react";
import { api } from "@/lib/api";
import { formatIDR, formatDate } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plus, Wallet } from "lucide-react";

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<Record<string, unknown>[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchExpenses = useCallback(() => {
    api.get("/expenses")
      .then((res) => setExpenses(res.data.data ?? []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchExpenses();
  }, [fetchExpenses]);

  if (loading) return <div className="animate-pulse">Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Expenses</h1>
          <p className="text-gray-600 dark:text-gray-400">Track and manage your expenses</p>
        </div>
        <button className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg">
          <Plus className="h-4 w-4" /> Add Expense
        </button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Expenses</CardTitle>
        </CardHeader>
        <CardContent>
          {expenses.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Wallet className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No expenses recorded yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {expenses.map((exp: Record<string, unknown>) => (
                <div key={exp.id} className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900 dark:text-white">{exp.title as string}</p>
                    <p className="text-xs text-gray-500">{(exp.category as Record<string, unknown>)?.name as string} &middot; {formatDate(exp.expenseDate as string)}</p>
                  </div>
                  <span className="font-medium text-gray-900 dark:text-white">{formatIDR(Number(exp.amount))}</span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
