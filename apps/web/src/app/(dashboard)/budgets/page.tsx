"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Target } from "lucide-react";

export default function BudgetsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Budgets</h1>
        <p className="text-gray-600 dark:text-gray-400">Set and monitor spending limits</p>
      </div>

      <Card>
        <CardContent className="text-center py-12 text-gray-500">
          <Target className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No budgets configured yet</p>
        </CardContent>
      </Card>
    </div>
  );
}
