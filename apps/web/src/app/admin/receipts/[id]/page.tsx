"use client";

import { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { api } from "@/lib/api";
import { Loader2, AlertTriangle, ArrowLeft, FileText, Building2, User, Calendar, Clock, CheckCircle, XCircle, Wallet, Image, Hash, ExternalLink } from "lucide-react";

interface ReceiptDetail {
  id: string;
  tenant: { id: string; name: string; slug: string };
  uploader: { email: string };
  fileName: string; fileType: string; fileSize: number; fileUrl: string;
  status: string;
  ocrProvider: string | null; ocrConfidence: number | null; errorMessage: string | null;
  processedAt: string | null; createdAt: string; updatedAt: string;
  blockchainTxHash: string | null; blockchainStatus: string | null;
  blockchainNetwork: string | null;
  blockchainSubmittedAt: string | null; blockchainConfirmedAt: string | null;
  receiptData: {
    merchantName: string | null; merchantAddress: string | null; merchantPhone: string | null;
    receiptNumber: string | null; transactionDate: string | null;
    subtotal: number | null; taxAmount: number | null; taxRate: number | null;
    discountAmount: number | null; totalAmount: number; currency: string;
    paymentMethod: string | null; lineItems: unknown; isVerified: boolean;
    verifier: { email: string } | null; verificationNotes: string | null;
    createdAt: string;
  } | null;
  expense: {
    id: string; title: string; amount: number; status: string;
    category: { id: string; name: string }; expenseDate: string;
  } | null;
}

const statusColors: Record<string, string> = {
  UPLOADED: "bg-gray-50 text-gray-600",
  PROCESSING: "bg-blue-50 text-blue-700",
  COMPLETED: "bg-green-50 text-green-700",
  FINALIZED: "bg-purple-50 text-purple-700",
  FAILED: "bg-red-50 text-red-700",
  REJECTED: "bg-orange-50 text-orange-700",
};

const blockchainColors: Record<string, string> = {
  PENDING: "bg-yellow-50 text-yellow-700",
  CONFIRMED: "bg-green-50 text-green-700",
  FAILED: "bg-red-50 text-red-700",
};

function fmtIDR(n: number) {
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(n);
}

function fmtBytes(n: number) {
  if (n < 1024) return `${n} B`;
  if (n < 1048576) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1048576).toFixed(1)} MB`;
}

export default function AdminReceiptDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [receipt, setReceipt] = useState<ReceiptDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchReceipt = useCallback(() => {
    setLoading(true); setError(null);
    api.get(`/admin/receipts/${params.id}`)
      .then((res) => setReceipt(res.data as ReceiptDetail))
      .catch((err) => setError(err instanceof Error ? err.message : "Gagal memuat detail struk"))
      .finally(() => setLoading(false));
  }, [params.id]);

  useEffect(() => { fetchReceipt(); }, [fetchReceipt]);

  function fmtDate(d: string | null) {
    if (!d) return "-";
    return new Date(d).toLocaleDateString("id-ID", { year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit" });
  }

  if (error) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <AlertTriangle className="h-12 w-12 text-red-400" />
      <p className="text-sm text-red-600">{error}</p>
      <button onClick={fetchReceipt} className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">Coba Lagi</button>
    </div>
  );

  if (loading) return <div className="flex items-center justify-center min-h-[60vh]"><Loader2 className="h-8 w-8 text-blue-600 animate-spin" /></div>;
  if (!receipt) return null;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button onClick={() => router.back()}
          className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Detail Struk</h1>
          <p className="text-sm text-gray-500 mt-0.5">{receipt.fileName}</p>
        </div>
        <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusColors[receipt.status] || "bg-gray-50 text-gray-600"}`}>
          {receipt.status}
        </span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Informasi File</h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoRow icon={FileText} label="Nama File" value={receipt.fileName} />
              <InfoRow icon={Hash} label="Tipe" value={receipt.fileType} />
              <InfoRow icon={Clock} label="Ukuran" value={fmtBytes(receipt.fileSize)} />
              <InfoRow icon={Calendar} label="Diupload" value={fmtDate(receipt.createdAt)} />
              {receipt.processedAt && <InfoRow icon={CheckCircle} label="Diproses" value={fmtDate(receipt.processedAt)} />}
              {receipt.errorMessage && (
                <div className="col-span-2 p-3 rounded-lg bg-red-50 border border-red-100">
                  <p className="text-xs font-medium text-red-700 mb-0.5">Error</p>
                  <p className="text-sm text-red-600">{receipt.errorMessage}</p>
                </div>
              )}
            </div>
            {receipt.fileUrl && (
              <a href={receipt.fileUrl} target="_blank" rel="noopener noreferrer"
                className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-200 transition-colors">
                <Image className="h-4 w-4" />
                Lihat Gambar
                <ExternalLink className="h-3 w-3" />
              </a>
            )}
          </div>

          {receipt.receiptData && (
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-semibold text-gray-900">Data OCR</h3>
                {receipt.receiptData.isVerified && (
                  <span className="text-xs font-medium text-green-700 bg-green-50 px-2 py-0.5 rounded-full flex items-center gap-1">
                    <CheckCircle className="h-3 w-3" /> Terverifikasi
                  </span>
                )}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <InfoRow icon={Building2} label="Merchant" value={receipt.receiptData.merchantName || "-"} />
                <InfoRow icon={Hash} label="No. Resi" value={receipt.receiptData.receiptNumber || "-"} />
                <InfoRow icon={Calendar} label="Tanggal Transaksi" value={receipt.receiptData.transactionDate ? fmtDate(receipt.receiptData.transactionDate) : "-"} />
                <InfoRow icon={Wallet} label="Total" value={fmtIDR(Number(receipt.receiptData.totalAmount))} />

                {receipt.receiptData.subtotal != null && (
                  <InfoRow icon={Wallet} label="Subtotal" value={fmtIDR(Number(receipt.receiptData.subtotal))} />
                )}
                {receipt.receiptData.taxAmount != null && (
                  <InfoRow icon={Wallet} label="Pajak" value={fmtIDR(Number(receipt.receiptData.taxAmount))} />
                )}
                {receipt.receiptData.discountAmount != null && (
                  <InfoRow icon={Wallet} label="Diskon" value={`- ${fmtIDR(Number(receipt.receiptData.discountAmount))}`} />
                )}
                <InfoRow icon={Wallet} label="Pembayaran" value={receipt.receiptData.paymentMethod || "-"} />
                {receipt.receiptData.merchantAddress && (
                  <div className="col-span-2">
                    <InfoRow icon={Building2} label="Alamat" value={receipt.receiptData.merchantAddress} />
                  </div>
                )}
              </div>
              {receipt.ocrConfidence != null && (
                <div className="mt-4 flex items-center gap-2 text-xs text-gray-500">
                  <CheckCircle className="h-3 w-3" />
                  OCR Confidence: {(Number(receipt.ocrConfidence) * 100).toFixed(0)}%
                  {receipt.ocrProvider && ` (${receipt.ocrProvider})`}
                </div>
              )}
              {receipt.receiptData.verifier && (
                <div className="mt-2 text-xs text-gray-500">
                  Diverifikasi oleh: {receipt.receiptData.verifier.email}
                  {receipt.receiptData.verificationNotes && ` — ${receipt.receiptData.verificationNotes}`}
                </div>
              )}
            </div>
          )}

          {receipt.expense && (
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-4">Pengeluaran Terkait</h3>
              <Link href={`/admin`}
                className="flex items-center justify-between p-4 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="text-sm font-medium text-gray-900">{receipt.expense.title}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{receipt.expense.category.name} &middot; {new Date(receipt.expense.expenseDate).toLocaleDateString("id-ID")}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-gray-900">{fmtIDR(Number(receipt.expense.amount))}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{receipt.expense.status}</p>
                </div>
              </Link>
            </div>
          )}
        </div>

        <div className="space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Uploader</h3>
            <div className="flex items-center gap-3 p-3 rounded-lg bg-gray-50">
              <div className="h-10 w-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <User className="h-5 w-5 text-blue-600" />
              </div>
              <div className="min-w-0">
                <p className="text-sm font-medium text-gray-900 break-all">{receipt.uploader.email}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Perusahaan</h3>
            <Link href={`/admin/tenants`}
              className="flex items-center gap-3 p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors">
              <div className="h-10 w-10 rounded-lg bg-indigo-50 flex items-center justify-center">
                <Building2 className="h-5 w-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">{receipt.tenant.name}</p>
                <p className="text-xs text-gray-500">{receipt.tenant.slug}</p>
              </div>
            </Link>
          </div>

          {receipt.blockchainTxHash && (
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-4">Blockchain</h3>
              <div className="space-y-3">
                <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${blockchainColors[receipt.blockchainStatus ?? "PENDING"] || "bg-yellow-50 text-yellow-700"}`}>
                  {receipt.blockchainStatus || "PENDING"}
                </span>
                <div>
                  <p className="text-xs text-gray-500 mb-0.5">Network</p>
                  <p className="text-sm font-medium text-gray-900">{receipt.blockchainNetwork || "base_sepolia"}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-0.5">Tx Hash</p>
                  <p className="text-sm font-mono text-gray-900 break-all">{receipt.blockchainTxHash}</p>
                </div>
                {receipt.blockchainConfirmedAt && (
                  <div>
                    <p className="text-xs text-gray-500 mb-0.5">Dikonfirmasi</p>
                    <p className="text-sm text-gray-900">{fmtDate(receipt.blockchainConfirmedAt)}</p>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoRow({ icon: Icon, label, value }: { icon: React.ElementType; label: string; value: string }) {
  return (
    <div className="space-y-0.5">
      <p className="text-xs text-gray-500">{label}</p>
      <p className="text-sm font-medium text-gray-900">{value}</p>
    </div>
  );
}
