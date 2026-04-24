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
  (response) => {
    const data = response.data;
    // skep 백엔드는 대부분 plain array를 돌려주지만 프론트 코드는 Spring의 PageResponse
    // ({ content, totalElements, totalPages, number, size }) 형태를 기대하는 경우가 많다.
    // 배열이면 PageResponse-like wrapper를 덧씌워 양쪽 코드가 모두 동작하게 한다.
    if (Array.isArray(data)) {
      const wrapped: any = [...data];
      wrapped.content = data;
      wrapped.totalElements = data.length;
      wrapped.totalPages = 1;
      wrapped.number = 0;
      wrapped.size = data.length;
      wrapped.first = true;
      wrapped.last = true;
      wrapped.empty = data.length === 0;
      return wrapped;
    }
    return data;
  },
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
