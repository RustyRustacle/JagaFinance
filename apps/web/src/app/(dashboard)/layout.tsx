"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuthStore } from "@/stores/auth";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";

const navItems = [
  { label: "Dashboard", href: "/dashboard", icon: "layout-dashboard" },
  { label: "Receipts", href: "/dashboard/receipts", icon: "receipt" },
  { label: "Expenses", href: "/dashboard/expenses", icon: "wallet" },
  { label: "Budgets", href: "/dashboard/budgets", icon: "target" },
  { label: "Settings", href: "/dashboard/settings", icon: "settings" },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login");
    }
  }, [isAuthenticated, router]);

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Sidebar items={navItems} pathname={pathname} />
      <div className="lg:pl-64">
        <Header />
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
