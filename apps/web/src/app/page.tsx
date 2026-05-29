import Image from "next/image";
import Link from "next/link";
import {
  Scan,
  Receipt,
  TrendingUp,
  Shield,
  BarChart3,
  Wallet,
  Target,
  ArrowRight,
  CheckCircle,
  Star,
  Smartphone,
  Check,
  Zap,
  Crown,
} from "lucide-react";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <Hero />
      <StatsBar />
      <Features />
      <HowItWorks />
      <PricingSection />
      <CTASection />
      <Footer />
    </div>
  );
}

function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-xl border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link href="/" className="flex items-center gap-2.5">
            <Image
              src="/logo.png"
              alt="JagaFinance"
              width={64}
              height={64}
              className="object-contain"
            />
            <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
              JagaFinance
            </span>
          </Link>

          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">Fitur</a>
            <a href="#how-it-works" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">Cara Kerja</a>
            <a href="#pricing" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">Harga</a>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="#"
              className="inline-flex items-center gap-2 text-sm font-medium text-white px-5 py-2.5 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 shadow-lg shadow-blue-600/25 hover:shadow-xl hover:shadow-blue-600/30 transition-all duration-200 hover:scale-[1.02]"
            >
              <Smartphone className="h-4 w-4" />
              Download di Play Store
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}

function Hero() {
  return (
    <section className="relative pt-32 pb-24 overflow-hidden">
      <div className="absolute inset-0 hero-gradient opacity-5" />
      <div className="absolute top-20 left-10 w-72 h-72 bg-blue-400/20 rounded-full blur-3xl animate-float" />
      <div className="absolute bottom-20 right-10 w-96 h-96 bg-indigo-400/20 rounded-full blur-3xl animate-float-delayed" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-blue-50 border border-blue-100 rounded-full text-sm font-medium text-blue-700 mb-8 animate-slide-up">
            <Star className="h-4 w-4 fill-blue-600" />
            Platform Manajemen Resi & Pengeluaran #1 di Indonesia
          </div>

          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold tracking-tight text-gray-900 leading-[1.1] mb-6">
            Digitalkan Resi{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 via-blue-500 to-indigo-600">
              Jadi Laporan Keuangan
            </span>
            {" "}Instan
          </h1>

          <p className="text-lg sm:text-xl text-gray-600 max-w-2xl mx-auto mb-10 leading-relaxed">
            JagaFinance mengubah resi fisik menjadi data keuangan digital secara otomatis.
            Lacak pengeluaran, kelola budget, dan buat laporan dalam hitungan detik.
          </p>

          <div className="flex items-center justify-center gap-4">
            <a
              href="#"
              className="group inline-flex items-center gap-2 px-8 py-3.5 text-white font-semibold rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 shadow-xl shadow-blue-600/30 hover:shadow-2xl hover:shadow-blue-600/40 transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]"
            >
              Unduh di Play Store
              <ArrowRight className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
            </a>
            <a
              href="#"
              className="inline-flex items-center gap-2 px-8 py-3.5 text-gray-700 font-semibold rounded-2xl border border-gray-200 hover:border-gray-300 hover:bg-gray-50 transition-all"
            >
              Unduh di App Store
            </a>
          </div>

          <div className="mt-12 flex items-center justify-center gap-8 text-sm text-gray-500">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              No credit card
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              Gratis selamanya
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              Setup 1 menit
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function StatsBar() {
  return (
    <section className="py-16 bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          {[
            { value: "10rb+", label: "Resi Diproses" },
            { value: "500+", label: "Perusahaan Aktif" },
            { value: "Rp 50M+", label: "Transaksi" },
            { value: "99.9%", label: "Akurasi OCR" },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-3xl sm:text-4xl font-bold text-white mb-1">{stat.value}</div>
              <div className="text-blue-200 text-sm">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Features() {
  const features = [
    {
      icon: Scan,
      title: "OCR Cerdas",
      desc: "Scan resi dengan AI. Ekstrak merchant, tanggal, total, dan detail pajak secara otomatis dengan akurasi tinggi.",
      gradient: "from-blue-500 to-cyan-500",
    },
    {
      icon: Wallet,
      title: "Manajemen Pengeluaran",
      desc: "Kategorisasi otomatis, lacak pengeluaran per proyek, dan pantau cash flow bisnis secara real-time.",
      gradient: "from-emerald-500 to-teal-500",
    },
    {
      icon: Target,
      title: "Budget & Alerts",
      desc: "Atur anggaran per kategori, dapatkan notifikasi saat mendekati limit, dan hindari overspending.",
      gradient: "from-amber-500 to-orange-500",
    },
    {
      icon: BarChart3,
      title: "Analitik & Laporan",
      desc: "Dashboard interaktif, tren bulanan, laporan pajak siap audit, dan export PDF/Excel 1 klik.",
      gradient: "from-purple-500 to-pink-500",
    },
    {
      icon: Shield,
      title: "Multi-Tenant & RBAC",
      desc: "Kelola banyak perusahaan dalam satu akun. Atur hak akses Admin, Finance, dan Viewer.",
      gradient: "from-red-500 to-rose-500",
    },
    {
      icon: Receipt,
      title: "Integrasi Pajak",
      desc: "Siap untuk pelaporan pajak dengan kategorisasi PPN, PPh, dan fitur tax deductible otomatis.",
      gradient: "from-indigo-500 to-violet-500",
    },
  ];

  return (
    <section id="features" className="py-24 bg-gray-50/50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            Semua yang Anda Butuhkan untuk{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
              Manajemen Keuangan
            </span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Platform all-in-one untuk digitalisasi resi, pelacakan pengeluaran, dan pelaporan keuangan bisnis Anda.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, i) => (
            <div
              key={feature.title}
              className="group relative p-8 rounded-2xl border border-gray-100 bg-white hover:shadow-xl hover:-translate-y-1 transition-all duration-300"
            >
              <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${feature.gradient} flex items-center justify-center mb-5 shadow-lg`}>
                <feature.icon className="h-6 w-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-3">{feature.title}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function HowItWorks() {
  const steps = [
    {
      num: "01",
      title: "Upload Resi",
      desc: "Foto atau upload resi fisik melalui web atau mobile. Format JPG, PNG, PDF didukung.",
      gradient: "from-blue-500 to-cyan-500",
    },
    {
      num: "02",
      title: "OCR Otomatis",
      desc: "AI kami mengekstrak data: merchant, tanggal, nominal, pajak — semuanya otomatis dalam detik.",
      gradient: "from-emerald-500 to-teal-500",
    },
    {
      num: "03",
      title: "Verifikasi & Kelola",
      desc: "Review hasil OCR, kategorisasi, dan approve. Lacak semua pengeluaran dalam satu dashboard.",
      gradient: "from-amber-500 to-orange-500",
    },
    {
      num: "04",
      title: "Laporan & Export",
      desc: "Generate laporan keuangan siap pajak. Export ke PDF, Excel, atau integrasikan dengan software akuntansi.",
      gradient: "from-purple-500 to-pink-500",
    },
  ];

  return (
    <section id="how-it-works" className="py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            Cara Kerjanya{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
              Sederhana
            </span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            4 langkah mudah untuk mengubah resi fisik menjadi laporan keuangan digital.
          </p>
        </div>

        <div className="grid md:grid-cols-4 gap-8">
          {steps.map((step, i) => (
            <div key={step.num} className="relative text-center">
              {i < steps.length - 1 && (
                <div className="hidden md:block absolute top-8 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-gray-200 to-gray-300" />
              )}
              <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${step.gradient} flex items-center justify-center mx-auto mb-6 shadow-lg relative`}>
                <span className="text-2xl font-bold text-white">{step.num}</span>
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-3">{step.title}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{step.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function PricingSection() {
  const plans = [
    {
      name: "Pro",
      slug: "pro",
      price: 5,
      description: "Cocok untuk bisnis kecil yang ingin mulai digitalisasi keuangan.",
      gradient: "from-blue-500 to-cyan-500",
      shadow: "shadow-blue-600/25",
      icon: Zap,
      features: [
        "Manajemen pengeluaran",
        "Upload nota (OCR)",
        "Laporan dasar",
        "Hingga 3 anggota tim",
        "Dukungan email",
      ],
    },
    {
      name: "Ultra",
      slug: "ultra",
      price: 10,
      description: "Untuk perusahaan dengan kebutuhan fitur lengkap dan prioritas.",
      gradient: "from-amber-500 to-orange-500",
      shadow: "shadow-amber-600/25",
      icon: Crown,
      popular: true,
      features: [
        "Manajemen pengeluaran",
        "Upload nota (OCR)",
        "Laporan lanjutan",
        "Anggota tim tidak terbatas",
        "Ekspor data",
        "Audit log",
        "Dukungan prioritas",
        "API akses",
      ],
    },
  ];

  return (
    <section id="pricing" className="py-24 bg-gray-50/50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            Pilih{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
              Paket Langganan
            </span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Nikmati fitur sesuai kebutuhan bisnis Anda. Beralih atau batalkan kapan saja.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-3xl mx-auto">
          {plans.map((plan) => (
            <div
              key={plan.slug}
              className={`relative p-8 rounded-2xl border bg-white transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${
                plan.popular
                  ? "border-amber-200 shadow-lg shadow-amber-600/10 ring-2 ring-amber-400/50"
                  : "border-gray-100 shadow-sm"
              }`}
            >
              {plan.popular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 bg-gradient-to-r from-amber-500 to-orange-500 text-white text-xs font-semibold rounded-full shadow-lg">
                  PALING POPULER
                </div>
              )}

              <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${plan.gradient} flex items-center justify-center mb-5 shadow-lg`}>
                <plan.icon className="h-6 w-6 text-white" />
              </div>

              <h3 className="text-xl font-bold text-gray-900 mb-2">{plan.name}</h3>
              <p className="text-sm text-gray-600 mb-6">{plan.description}</p>

              <div className="mb-8">
                <span className="text-5xl font-bold text-gray-900">${plan.price}</span>
                <span className="text-gray-500 ml-2">/bulan</span>
              </div>

              <ul className="space-y-3 mb-8">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-3">
                    <Check className="h-5 w-5 text-green-500 mt-0.5 shrink-0" />
                    <span className="text-sm text-gray-700">{feature}</span>
                  </li>
                ))}
              </ul>

              <a
                href="#"
                className={`block text-center w-full py-3 px-6 rounded-xl font-semibold transition-all duration-200 hover:scale-[1.02] active:scale-[0.98] ${
                  plan.popular
                    ? "text-white bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 shadow-lg shadow-amber-600/25"
                    : "text-gray-700 bg-gray-100 hover:bg-gray-200"
                }`}
              >
                Pilih {plan.name}
              </a>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function CTASection() {
  return (
    <section className="py-24 bg-gradient-to-br from-gray-900 via-gray-900 to-indigo-950 relative overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-blue-500/10 rounded-full blur-3xl" />
      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6">
          Siap Digitalkan Manajemen{" "}
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400">
            Keuangan Bisnis?
          </span>
        </h2>
        <p className="text-lg text-gray-300 mb-10 max-w-2xl mx-auto">
          Bergabung dengan 500+ perusahaan yang sudah menggunakan JagaFinance.
          Gratis selamanya, tanpa kartu kredit.
        </p>
        <div className="flex items-center justify-center gap-4">
          <a
            href="#"
            className="inline-flex items-center gap-2 px-8 py-3.5 text-gray-900 font-semibold rounded-2xl bg-white hover:bg-gray-100 shadow-xl transition-all duration-200 hover:scale-[1.02]"
          >
            Download di Play Store
            <ArrowRight className="h-5 w-5" />
          </a>
          <a
            href="#"
            className="inline-flex items-center gap-2 px-8 py-3.5 text-white font-semibold rounded-2xl border border-gray-600 hover:border-gray-500 hover:bg-white/5 transition-all"
          >
            Download di App Store
          </a>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="bg-gray-50 border-t border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid md:grid-cols-4 gap-8">
          <div className="md:col-span-2">
            <Link href="/" className="flex items-center gap-2.5 mb-4">
              <Image
                src="/logo.png"
                alt="JagaFinance"
                width={64}
                height={64}
                className="object-contain"
              />
              <span className="text-lg font-bold text-gray-900">JagaFinance</span>
            </Link>
            <p className="text-sm text-gray-600 max-w-sm">
              Platform B2B untuk digitalisasi resi dan manajemen pengeluaran bisnis.
              Ubah resi fisik jadi laporan keuangan siap audit dalam hitungan detik.
            </p>
          </div>
          <div>
            <h4 className="font-semibold text-gray-900 mb-4">Produk</h4>
            <ul className="space-y-3">
              {["Fitur", "Harga", "API", "Integrasi"].map((item) => (
                <li key={item}>
                  <a href={item === "Harga" ? "#pricing" : "#"} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">{item}</a>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="font-semibold text-gray-900 mb-4">Perusahaan</h4>
            <ul className="space-y-3">
              {["Tentang", "Blog", "Karir", "Kontak"].map((item) => (
                <li key={item}>
                  <a href="#" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">{item}</a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="border-t border-gray-200 mt-10 pt-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-500">&copy; 2026 JagaFinance. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <a href="#" className="text-sm text-gray-500 hover:text-gray-700">Kebijakan Privasi</a>
            <a href="#" className="text-sm text-gray-500 hover:text-gray-700">Syarat & Ketentuan</a>
            <Link href="/admin/login" className="text-sm text-gray-400 hover:text-gray-600">&middot; Admin</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
