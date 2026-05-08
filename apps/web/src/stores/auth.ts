import { create } from "zustand";
import { persist } from "zustand/middleware";

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: { id: string; email: string; name?: string } | null;
  isAuthenticated: boolean;
  // GANTI void menjadi any supaya bisa mengembalikan data token
  login: (email: string, password: string) => Promise<any>; 
  register: (data: {
    email: string;
    password: string;
    name: string;
    tenantName: string;
    tenantSlug: string;
  }) => Promise<any>; // GANTI void menjadi any
  logout: () => void;
  setToken: (token: string) => void;
}

const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";

async function fetchAPI(endpoint: string, options: RequestInit) {
  const res = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error?.message || "Request failed");
  }

  return res.json();
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      isAuthenticated: false,

      login: async (email: string, password: string) => {
        const { data } = await fetchAPI("/auth/login", {
          method: "POST",
          body: JSON.stringify({ email, password }),
        });

        localStorage.setItem("accessToken", data.accessToken);
        localStorage.setItem("refreshToken", data.refreshToken);
        
        set({
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          user: data.user,
          isAuthenticated: true,
        });

        // TAMBAHKAN INI: Supaya data bisa dipakai di login/page.tsx
        return data; 
      },

      register: async (data) => {
        const { data: result } = await fetchAPI("/auth/register", {
          method: "POST",
          body: JSON.stringify(data),
        });

        localStorage.setItem("accessToken", result.accessToken);
        localStorage.setItem("refreshToken", result.refreshToken);
        
        set({
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          user: result.user,
          isAuthenticated: true,
        });

        // TAMBAHKAN INI
        return result; 
      },

      logout: () => {
        localStorage.removeItem("accessToken");
        localStorage.removeItem("refreshToken");
        set({
          accessToken: null,
          refreshToken: null,
          user: null,
          isAuthenticated: false,
        });
      },

      setToken: (token: string) => {
        set({ accessToken: token });
      },
    }),
    {
      name: "vaultledger-auth",
      partialize: (state) => ({
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);