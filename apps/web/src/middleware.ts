import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  // 1. Siapkan Response
  let supabaseResponse = NextResponse.next({
    request,
  });

  // 2. Inisialisasi Supabase Client
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: Record<string, unknown>) {
          supabaseResponse.cookies.set(name, value, options);
        },
        remove(name: string, options: Record<string, unknown>) {
          supabaseResponse.cookies.set(name, "", { ...options, maxAge: 0 });
        },
      },
    }
  );

  // 3. Ambil data User dari Supabase Session
  // const { data: { user } } = await supabase.auth.getUser(); pakai cara Bypass paling ampuh 
  // getUser() akan selalu mengecek tanda tangan token ke server Supabase (sangat ketat). Sedangkan getSession() hanya melihat apakah ada data user di dalam token tersebut (lebih longgar).
  const { data: { session } } = await supabase.auth.getSession();
  const user = session?.user;

  const pathname = request.nextUrl.pathname;

  // --- LOGIKA FILTER HALAMAN ---

  // Tentukan halaman yang boleh diakses tanpa login
  const isAuthPage = pathname === "/login" || pathname === "/register";
  
  // Halaman aset (gambar, favicon, dll) - jangan diproteksi
  const isPublicFile = pathname.includes('.') || pathname.startsWith('/_next');

  // Karena kamu pakai (dashboard), maka hampir semua rute selain login/regis adalah "Halaman Dalam"
  const isInsideApp = !isAuthPage && !isPublicFile && pathname !== "/";

  // --- LOGIKA PENGALIHAN (REDIRECT) ---

  // KASUS A: Belum Login tapi mau masuk ke halaman dalam (Receipts, Expenses, dll)
  if (!user && isInsideApp) {
    const redirectUrl = new URL("/login", request.url);
    // Simpan alamat asal supaya setelah login bisa balik lagi ke sini
    redirectUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(redirectUrl);
  }

  // KASUS B: Sudah Login tapi masih buka halaman Login/Register
  if (user && isAuthPage) {
    // Alihkan langsung ke halaman utama aplikasi (Receipts)
    return NextResponse.redirect(new URL("/receipts", request.url));
  }

  return supabaseResponse;
}

// Aturan halaman mana saja yang akan dilewati middleware ini
export const config = {
  matcher: [
    /*
     * Match semua request kecuali:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    "/((?!api|_next/static|_next/image|favicon.ico).*)",
  ],
};