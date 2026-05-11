import { create } from "zustand";
import { persist } from "zustand/middleware";
import { supabase } from "@/lib/supabase";

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: { id: string; email: string; name?: string } | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: {
    email: string;
    password: string;
    name: string;
    tenantName: string;
    tenantSlug: string;
  }) => Promise<void>;
  logout: () => void;
  setToken: (token: string) => void;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";

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

        const { error } = await supabase.auth.setSession({
          access_token: data.accessToken,
          refresh_token: data.refreshToken,
        });

        if (error) throw error;

        localStorage.setItem("accessToken", data.accessToken);
        localStorage.setItem("refreshToken", data.refreshToken);

        set({
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          user: data.user,
          isAuthenticated: true,
        });
      },

      register: async (data) => {
        const { data: result } = await fetchAPI("/auth/register", {
          method: "POST",
          body: JSON.stringify(data),
        });

        const { error } = await supabase.auth.setSession({
          access_token: result.accessToken,
          refresh_token: result.refreshToken,
        });

        if (error) throw error;

        localStorage.setItem("accessToken", result.accessToken);
        localStorage.setItem("refreshToken", result.refreshToken);

        set({
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          user: result.user,
          isAuthenticated: true,
        });
      },

      logout: async () => {
        const accessToken = localStorage.getItem("accessToken");
        if (accessToken) {
          try {
            await fetch(`${API_URL}/auth/logout`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
            });
          } catch {
            
          }
        }

        await supabase.auth.signOut();
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