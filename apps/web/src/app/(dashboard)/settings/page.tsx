"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useAuthStore } from "@/stores/auth";
import { AlertTriangle } from "lucide-react";

export default function SettingsPage() {
  const logout = useAuthStore((state) => state.logout);
  const [tenant, setTenant] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.get("/tenants/current")
      .then((res) => setTenant((res.data as { data: Record<string, unknown> }).data))
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat pengaturan"))
      .finally();
  }, []);

  if (error) return (
    <div className="flex flex-col items-center justify-start min-h-[60vh] gap-4 pt-12">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
    </div>
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Settings</h1>
        <p className="text-gray-600 dark:text-gray-400">Manage your workspace settings</p>
      </div>

      {tenant && (
        <Card>
          <CardHeader>
            <CardTitle>Workspace</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm text-gray-500">Company Name</label>
              <p className="font-medium text-gray-900 dark:text-white">{tenant.name as string}</p>
            </div>
            <div>
              <label className="text-sm text-gray-500">Workspace URL</label>
              <p className="font-mono text-sm text-gray-900 dark:text-white">{tenant.slug as string}</p>
            </div>
            <div>
              <label className="text-sm text-gray-500">Currency</label>
              <p className="text-gray-900 dark:text-white">{tenant.currency as string}</p>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-red-600">Danger Zone</CardTitle>
        </CardHeader>
        <CardContent>
          <button onClick={logout} className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg">
            Sign Out
          </button>
        </CardContent>
      </Card>
    </div>
  );
}
