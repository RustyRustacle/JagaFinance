"use client";

import { useAuthStore } from "@/stores/auth";

export function Header() {
  const user = useAuthStore((state) => state.user);

  return (
    <header className="sticky top-0 z-40 h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-end px-6">
      <div className="flex items-center gap-3">
        <div className="h-8 w-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-sm font-medium">
          {user?.name?.charAt(0).toUpperCase() || user?.email?.charAt(0).toUpperCase()}
        </div>
        <div className="text-sm">
          <p className="font-medium text-gray-900 dark:text-white">{user?.name || "User"}</p>
          <p className="text-xs text-gray-500">{user?.email}</p>
        </div>
      </div>
    </header>
  );
}
