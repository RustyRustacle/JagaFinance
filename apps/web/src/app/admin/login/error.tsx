"use client";

import { useEffect } from "react";
import Link from "next/link";
import { AlertTriangle, RefreshCw, LogIn } from "lucide-react";

export default function AdminLoginError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 p-8">
      <div className="bg-white rounded-2xl border border-gray-200 p-10 max-w-sm w-full text-center">
        <div className="h-14 w-14 rounded-xl bg-red-50 border border-red-100 flex items-center justify-center mx-auto mb-5">
          <AlertTriangle className="h-7 w-7 text-red-500" />
        </div>
        <h2 className="text-lg font-bold text-gray-900 mb-1">Gagal Memuat</h2>
        <p className="text-sm text-gray-500 mb-6">Terjadi kesalahan saat memuat halaman login.</p>
        <div className="flex items-center justify-center gap-3">
          <button onClick={reset}
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors">
            <RefreshCw className="h-4 w-4" />
            Coba Lagi
          </button>
          <Link href="/"
            className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-200 transition-colors">
            <LogIn className="h-4 w-4" />
            Beranda
          </Link>
        </div>
      </div>
    </div>
  );
}
