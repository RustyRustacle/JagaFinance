"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { formatIDR } from "@/lib/utils";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { TrendingUp, Receipts, AlertTriangle, Clock } from "lucide-react";

export default function DashboardPage() {
  const [overview, setOverview] = useState<Record<string, unknown> | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/dashboard/overview")
      .then((res) => setOverview(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="animate-pulse space-y-4">Loading...</div>;
  }

  const stats = [
    {
      label: "Total Expenses",
      value: formatIDR((overview?.total_expenses as number) ?? 0),
      icon: TrendingUp,
      color: "text-blue-600",
    },
    {
      label: "Receipts This Month",
      value: (overview?.total_receipts as number) ?? 0,
      icon: Receipts,
      color: "text-green-600",
    },
    {
      label: "Pending Reviews",
      value: (overview?.pending_reviews as number) ?? 0,
      icon: Clock,
      color: "text-yellow-600",
    },
    {
      label: "Budget Alerts",
      value: (overview?.budget_alerts as number) ?? 0,
      icon: AlertTriangle,
      color: "text-red-600",
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Dashboard
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Overview of your expenses and receipts
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.label}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-600 dark:text-gray-400">
                {stat.label}
              </CardTitle>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-gray-900 dark:text-white">
                {stat.value}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Expenses by Category</CardTitle>
          </CardHeader>
          <CardContent>
            {(overview?.expenses_by_category as { category: string; amount: number; percentage: number }[] | undefined)?.map((cat) => (
              <div key={cat.category} className="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800 last:border-0">
                <span className="text-sm text-gray-700 dark:text-gray-300">{cat.category}</span>
                <div className="flex items-center gap-4">
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {formatIDR(cat.amount)}
                  </span>
                  <span className="text-xs text-gray-500 w-12 text-right">
                    {cat.percentage.toFixed(1)}%
                  </span>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Monthly Trend</CardTitle>
          </CardHeader>
          <CardContent>
            {(overview?.monthly_trend as { month: string; amount: number }[] | undefined)?.map((m) => (
              <div key={m.month} className="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800 last:border-0">
                <span className="text-sm text-gray-700 dark:text-gray-300">{m.month}</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">
                  {formatIDR(m.amount)}
                </span>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
