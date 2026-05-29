"use client";

import { useEffect } from "react";
import Link from "next/link";
import { AlertTriangle, RefreshCw, Home } from "lucide-react";

export default function RootError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 p-8">
      <div className="bg-white rounded-2xl shadow-xl border border-gray-200 p-12 max-w-md w-full text-center">
        <div className="h-16 w-16 rounded-2xl bg-red-50 border border-red-100 flex items-center justify-center mx-auto mb-6">
          <AlertTriangle className="h-8 w-8 text-red-500" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Terjadi Kesalahan</h1>
        <p className="text-sm text-gray-500 mb-8">Maaf, terjadi kesalahan yang tidak terduga. Silakan coba lagi.</p>
        <div className="flex items-center justify-center gap-3">
          <button onClick={reset}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 text-white text-sm font-medium rounded-xl hover:bg-blue-700 transition-colors">
            <RefreshCw className="h-4 w-4" />
            Coba Lagi
          </button>
          <Link href="/"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-gray-100 text-gray-700 text-sm font-medium rounded-xl hover:bg-gray-200 transition-colors">
            <Home className="h-4 w-4" />
            Beranda
          </Link>
        </div>
        {error.digest && (
          <p className="mt-6 text-xs text-gray-400">Error ID: {error.digest}</p>
        )}
      </div>
    </div>
  );
}
