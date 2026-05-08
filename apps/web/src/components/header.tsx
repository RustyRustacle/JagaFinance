"use client";

import { useAuthStore } from "@/stores/auth";
import { Bell, Search } from "lucide-react";

export function Header() {
  const user = useAuthStore((state) => state.user);

  return (
    <header className="sticky top-0 z-40 h-16 bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl border-b border-gray-100 dark:border-gray-800 flex items-center justify-between px-6">
      <div className="flex items-center flex-1 max-w-md">
        <div className="relative w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Cari..."
            className="w-full pl-10 pr-4 py-2 text-sm bg-gray-100 dark:bg-gray-800 border-0 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:bg-white dark:focus:bg-gray-800 transition-all"
          />
        </div>
      </div>
      <div className="flex items-center gap-4">
        <button className="relative p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition-colors">
          <Bell className="h-5 w-5 text-muted-foreground" />
          <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-blue-600 ring-2 ring-white dark:ring-gray-900" />
        </button>
        <div className="flex items-center gap-3 pl-4 border-l border-gray-100 dark:border-gray-800">
          <div className="h-9 w-9 rounded-xl gradient-primary flex items-center justify-center text-white text-sm font-semibold shadow-lg shadow-blue-600/20">
            {user?.name?.charAt(0).toUpperCase() || user?.email?.charAt(0).toUpperCase()}
          </div>
          <div className="text-sm">
            <p className="font-medium text-gray-900 dark:text-white">{user?.name || "User"}</p>
            <p className="text-xs text-muted-foreground">{user?.email}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
