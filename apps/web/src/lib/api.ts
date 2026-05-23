const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";

let isRefreshing = false;
let pendingRequests: Array<(token: string) => void> = [];

async function refreshToken(): Promise<string | null> {
  const refreshTokenValue = localStorage.getItem("refreshToken");
  if (!refreshTokenValue) return null;

  try {
    const res = await fetch(`${API_URL}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken: refreshTokenValue }),
    });

    if (!res.ok) {
      localStorage.removeItem("accessToken");
      localStorage.removeItem("refreshToken");
      window.location.href = "/login";
      return null;
    }

    const data = await res.json();
    const newToken = data.data.accessToken;
    localStorage.setItem("accessToken", newToken);
    if (data.data.refreshToken) {
      localStorage.setItem("refreshToken", data.data.refreshToken);
    }
    return newToken;
  } catch {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    window.location.href = "/login";
    return null;
  }
}

interface FetchOptions {
  method?: string;
  body?: unknown;
  headers?: Record<string, string>;
  formData?: FormData;
}

async function request(endpoint: string, options: FetchOptions = {}): Promise<{ success: boolean; data?: unknown; meta?: unknown; error?: unknown }> {
  const token = localStorage.getItem("accessToken");

  const headers: Record<string, string> = {
    ...(options.formData ? {} : { "Content-Type": "application/json" }),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const fetchOptions: RequestInit = {
    method: options.method || "GET",
    headers,
    body: options.formData
      ? options.formData
      : options.body
        ? JSON.stringify(options.body)
        : undefined,
  };

  let res = await fetch(`${API_URL}${endpoint}`, fetchOptions);

  if (res.status === 401 && !options.headers?.Authorization?.startsWith("Bearer ")) {
    if (!isRefreshing) {
      isRefreshing = true;
      const newToken = await refreshToken();

      if (newToken) {
        headers.Authorization = `Bearer ${newToken}`;
        fetchOptions.headers = { ...headers };
        res = await fetch(`${API_URL}${endpoint}`, fetchOptions);
      }

      isRefreshing = false;
      pendingRequests.forEach((cb) => cb(newToken ?? ""));
      pendingRequests = [];
    } else {
      const newToken = await new Promise<string>((resolve) => {
        pendingRequests.push(resolve);
      });
      headers.Authorization = `Bearer ${newToken}`;
      fetchOptions.headers = { ...headers };
      res = await fetch(`${API_URL}${endpoint}`, fetchOptions);
    }
  }

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error((data as { error?: { message?: string } }).error?.message || "Request failed");
  }

  return res.json() as Promise<{ success: boolean; data?: unknown; meta?: unknown; error?: unknown }>;
}

export const api = {
  get: (endpoint: string) => request(endpoint, { method: "GET" }),
  post: (endpoint: string, body?: unknown, headers?: Record<string, string>) =>
    request(endpoint, {
      method: "POST",
      body,
      ...(body instanceof FormData ? { formData: body } : {}),
      headers,
    }),
  patch: (endpoint: string, body: unknown) =>
    request(endpoint, { method: "PATCH", body }),
  delete: (endpoint: string) => request(endpoint, { method: "DELETE" }),
};
