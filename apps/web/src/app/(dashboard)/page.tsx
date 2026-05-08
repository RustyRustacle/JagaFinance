"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { api } from "@/lib/api";
import { formatIDR } from "@/lib/utils";
import {
  TrendingUp,
  Receipt,
  Clock,
  AlertTriangle,
  Camera,
  Scan,
  Upload,
  X,
  ChevronRight,
  BarChart3,
  Wallet,
  Building2,
  CalendarDays,
  ArrowUpRight,
  ArrowDownRight,
  Loader2,
} from "lucide-react";

interface DashboardData {
  total_expenses: number;
  total_receipts: number;
  pending_reviews: number;
  budget_alerts: number;
  expenses_by_category: { category: string; amount: number; percentage: number }[];
  monthly_trend: { month: string; amount: number }[];
  monthly_change?: number;
}

const monthNames: Record<string, string> = {
  "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr",
  "05": "Mei", "06": "Jun", "07": "Jul", "08": "Agu",
  "09": "Sep", "10": "Okt", "11": "Nov", "12": "Des",
};

export default function DashboardPage() {
  const [overview, setOverview] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [showScanner, setShowScanner] = useState(false);

  useEffect(() => {
    api.get("/dashboard/overview")
      .then((res) => setOverview(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const change =
    overview?.monthly_trend && overview.monthly_trend.length >= 2
      ? ((overview.monthly_trend[2]?.amount ?? 0) - (overview.monthly_trend[1]?.amount ?? 0))
      : 0;

  const stats = [
    {
      label: "Total Pengeluaran",
      value: formatIDR(overview?.total_expenses ?? 0),
      icon: Wallet,
      gradient: "gradient-primary",
      change,
      changeLabel: "vs bulan lalu",
    },
    {
      label: "Resi Bulan Ini",
      value: (overview?.total_receipts ?? 0).toString(),
      icon: Receipt,
      gradient: "gradient-success",
      change: 0,
    },
    {
      label: "Menunggu Review",
      value: (overview?.pending_reviews ?? 0).toString(),
      icon: Clock,
      gradient: "gradient-warning",
      change: 0,
    },
    {
      label: "Peringatan Budget",
      value: (overview?.budget_alerts ?? 0).toString(),
      icon: AlertTriangle,
      gradient: "gradient-danger",
      change: 0,
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 text-blue-600 animate-spin" />
          <p className="text-sm text-muted-foreground">Memuat dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground mt-1">
            Ringkasan pengeluaran dan resi periode ini
          </p>
        </div>
        <button
          onClick={() => setShowScanner(true)}
          className="group relative inline-flex items-center gap-2.5 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-medium rounded-xl shadow-lg shadow-blue-600/25 hover:shadow-xl hover:shadow-blue-600/30 hover:scale-[1.02] active:scale-[0.98] transition-all duration-200"
        >
          <Camera className="h-5 w-5" />
          <span>Scan Resi</span>
        </button>
      </div>

      <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat, i) => (
          <div
            key={stat.label}
            className="card-glow card-hover group relative rounded-2xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm"
            style={{ animationDelay: `${i * 80}ms` }}
          >
            <div className="flex items-start justify-between mb-4">
              <div className={`p-2.5 rounded-xl ${stat.gradient} text-white shadow-lg ${stat.gradient.replace("gradient", "shadow")}/25`}>
                <stat.icon className="h-5 w-5" />
              </div>
              {stat.change !== 0 && (
                <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full ${
                  stat.change >= 0
                    ? "bg-rose-50 text-rose-600 dark:bg-rose-900/20 dark:text-rose-400"
                    : "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400"
                }`}>
                  {stat.change >= 0 ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
                  {Math.abs(stat.change).toFixed(0)}%
                </span>
              )}
            </div>
            <p className="text-sm text-muted-foreground mb-1">{stat.label}</p>
            <p className="text-2xl font-bold tracking-tight">{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-7">
        <div className="lg:col-span-4 card-glow card-hover rounded-2xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold">Kategori Pengeluaran</h3>
              <p className="text-sm text-muted-foreground mt-0.5">Distribusi bulan ini</p>
            </div>
            <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/20">
              <BarChart3 className="h-5 w-5 text-blue-600" />
            </div>
          </div>
          <div className="space-y-4">
            {(overview?.expenses_by_category?.length ?? 0) > 0 ? (
              overview!.expenses_by_category.map((cat, i) => (
                <div key={cat.category} className="animate-slide-up" style={{ animationDelay: `${i * 60}ms` }}>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-sm font-medium">{cat.category}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-semibold">{formatIDR(cat.amount)}</span>
                      <span className="text-xs text-muted-foreground w-10 text-right">{cat.percentage.toFixed(1)}%</span>
                    </div>
                  </div>
                  <div className="h-2 bg-gray-100 dark:bg-gray-800 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-blue-500 to-indigo-500 transition-all duration-1000 ease-out"
                      style={{ width: `${cat.percentage}%` }}
                    />
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8">
                <BarChart3 className="h-10 w-10 mx-auto mb-3 text-muted-foreground/50" />
                <p className="text-sm text-muted-foreground">Belum ada data pengeluaran</p>
              </div>
            )}
          </div>
        </div>

        <div className="lg:col-span-3 card-glow card-hover rounded-2xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold">Tren Bulanan</h3>
              <p className="text-sm text-muted-foreground mt-0.5">3 bulan terakhir</p>
            </div>
            <div className="p-2 rounded-lg bg-emerald-50 dark:bg-emerald-900/20">
              <CalendarDays className="h-5 w-5 text-emerald-600" />
            </div>
          </div>
          <div className="space-y-3">
            {(overview?.monthly_trend?.length ?? 0) > 0 ? (
              [...overview!.monthly_trend].reverse().map((m, i) => {
                const monthKey = m.month.split("-")[1];
                const maxAmount = Math.max(...overview!.monthly_trend.map((t) => t.amount), 1);
                const barHeight = (m.amount / maxAmount) * 100;
                return (
                  <div key={m.month} className="animate-slide-up flex items-center gap-4" style={{ animationDelay: `${i * 80}ms` }}>
                    <span className="text-sm text-muted-foreground w-12 shrink-0">
                      {monthNames[monthKey] || m.month}
                    </span>
                    <div className="flex-1 h-8 bg-gray-100 dark:bg-gray-800 rounded-lg overflow-hidden relative">
                      <div
                        className="h-full rounded-lg bg-gradient-to-r from-blue-500 to-indigo-500 transition-all duration-1000 ease-out"
                        style={{ width: `${barHeight}%` }}
                      />
                    </div>
                    <span className="text-sm font-semibold w-28 text-right">{formatIDR(m.amount)}</span>
                  </div>
                );
              })
            ) : (
              <div className="text-center py-8">
                <CalendarDays className="h-10 w-10 mx-auto mb-3 text-muted-foreground/50" />
                <p className="text-sm text-muted-foreground">Belum ada data tren</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {showScanner && <CameraScanner onClose={() => setShowScanner(false)} />}
    </div>
  );
}

function CameraScanner({ onClose }: { onClose: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [captured, setCaptured] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startCamera = useCallback(async () => {
    try {
      setError(null);
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment", width: { ideal: 1920 }, height: { ideal: 1080 } },
      });
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
    } catch {
      setError("Tidak dapat mengakses kamera. Pastikan izin kamera diberikan.");
    }
  }, []);

  useEffect(() => {
    startCamera();
    return () => {
      stream?.getTracks().forEach((t) => t.stop());
    };
  }, []);

  const capture = () => {
    const video = videoRef.current;
    const canvas = canvasRef.current;
    if (!video || !canvas) return;

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext("2d")?.drawImage(video, 0, 0);
    setCaptured(canvas.toDataURL("image/jpeg", 0.9));
    stream?.getTracks().forEach((t) => t.stop());
    setStream(null);
  };

  const retake = () => {
    setCaptured(null);
    startCamera();
  };

  const uploadCapture = async () => {
    if (!captured) return;
    setUploading(true);
    try {
      const blob = await (await fetch(captured)).blob();
      const file = new File([blob], `scan-${Date.now()}.jpg`, { type: "image/jpeg" });
      const formData = new FormData();
      formData.append("file", file);
      await api.post("/receipts/upload", formData, {
        "Content-Type": "multipart/form-data",
      });
      onClose();
    } catch (err) {
      setError("Gagal mengupload. Coba lagi.");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in">
      <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-scale-in">
        <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-gray-800">
          <h3 className="font-semibold text-lg">Scan Resi</h3>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition-colors">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="relative bg-black aspect-[4/3]">
          {!captured ? (
            <video ref={videoRef} autoPlay playsInline className="w-full h-full object-cover" />
          ) : (
            <img src={captured} alt="Captured" className="w-full h-full object-contain" />
          )}
          <div className="absolute inset-0 border-[3px] border-dashed border-white/30 rounded-2xl m-8 pointer-events-none" />

          {error && (
            <div className="absolute bottom-4 left-4 right-4 bg-red-500/90 text-white text-sm px-4 py-2 rounded-lg">
              {error}
            </div>
          )}
        </div>

        <div className="flex items-center justify-center gap-3 p-4">
          {!captured ? (
            <>
              <button
                onClick={capture}
                className="flex items-center gap-2 px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-xl transition-all duration-200 hover:scale-105 active:scale-95 shadow-lg shadow-blue-600/25"
              >
                <Camera className="h-5 w-5" />
                Ambil Foto
              </button>
              <button
                onClick={onClose}
                className="px-6 py-2.5 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 font-medium rounded-xl transition-colors"
              >
                Batal
              </button>
            </>
          ) : (
            <>
              <button
                onClick={uploadCapture}
                disabled={uploading}
                className="flex items-center gap-2 px-6 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 disabled:opacity-60 text-white font-medium rounded-xl transition-all duration-200 hover:scale-105 active:scale-95 shadow-lg shadow-blue-600/25"
              >
                {uploading ? (
                  <Loader2 className="h-5 w-5 animate-spin" />
                ) : (
                  <Upload className="h-5 w-5" />
                )}
                {uploading ? "Mengupload..." : "Upload"}
              </button>
              <button
                onClick={retake}
                disabled={uploading}
                className="flex items-center gap-2 px-6 py-2.5 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 font-medium rounded-xl transition-colors"
              >
                <Scan className="h-5 w-5" />
                Ulang
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
