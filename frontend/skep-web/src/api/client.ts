import axios from "axios";

const client = axios.create({
  baseURL: "",
  headers: {
    "Content-Type": "application/json",
  },
});

// Request interceptor: attach JWT token
client.interceptors.request.use((config) => {
  const token = localStorage.getItem("skep_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor: unwrap data, handle 401
let isRefreshing = false;

client.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return Promise.reject(error);
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem("skep_refresh_token");
        if (!refreshToken) {
          throw new Error("No refresh token");
        }

        const response = await axios.post("/api/auth/refresh", {
          refreshToken,
        });

        const { token, refreshToken: newRefresh } = response.data;
        localStorage.setItem("skep_token", token);
        localStorage.setItem("skep_refresh_token", newRefresh);

        originalRequest.headers.Authorization = `Bearer ${token}`;
        return client(originalRequest);
      } catch {
        localStorage.removeItem("skep_token");
        localStorage.removeItem("skep_refresh_token");
        localStorage.removeItem("skep_user");
        window.location.href = "/login";
        return Promise.reject(error);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export default client;
