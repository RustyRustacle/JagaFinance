const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";

interface FetchOptions {
  method?: string;
  body?: unknown;
  headers?: Record<string, string>;
  formData?: FormData;
}

async function request(endpoint: string, options: FetchOptions = {}) {
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

  const res = await fetch(`${API_URL}${endpoint}`, fetchOptions);

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error?.message || "Request failed");
  }

  return res.json();
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
