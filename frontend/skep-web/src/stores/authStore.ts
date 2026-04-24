import { create } from "zustand";
import type { User } from "@/types";

interface AuthState {
  user: User | null;
  token: string | null;
  refreshToken: string | null;

  login: (data: { token: string; refreshToken: string; user: User }) => void;
  logout: () => void;
  initialize: () => void;
  setUser: (user: User) => void;
}

// localStorage 에서 동기적으로 초기값 로드 — 새로고침 시 AuthGuard 가 token:null 로 잠깐 보고
// 로그인 페이지로 리다이렉트해버리는 것 방지
function loadInitial(): Pick<AuthState, "user" | "token" | "refreshToken"> {
  try {
    const token = localStorage.getItem("skep_token");
    const refreshToken = localStorage.getItem("skep_refresh_token");
    const userJson = localStorage.getItem("skep_user");
    if (token && userJson) {
      return { token, refreshToken, user: JSON.parse(userJson) as User };
    }
  } catch { /* noop */ }
  return { user: null, token: null, refreshToken: null };
}

export const useAuthStore = create<AuthState>((set) => ({
  ...loadInitial(),

  login: (data) => {
    localStorage.setItem("skep_token", data.token);
    localStorage.setItem("skep_refresh_token", data.refreshToken);
    localStorage.setItem("skep_user", JSON.stringify(data.user));
    set({
      token: data.token,
      refreshToken: data.refreshToken,
      user: data.user,
    });
  },

  logout: () => {
    localStorage.removeItem("skep_token");
    localStorage.removeItem("skep_refresh_token");
    localStorage.removeItem("skep_user");
    set({ token: null, refreshToken: null, user: null });
  },

  setUser: (user) => {
    localStorage.setItem("skep_user", JSON.stringify(user));
    set({ user });
  },

  initialize: () => {
    const token = localStorage.getItem("skep_token");
    const refreshToken = localStorage.getItem("skep_refresh_token");
    const userJson = localStorage.getItem("skep_user");

    if (token && userJson) {
      try {
        const user = JSON.parse(userJson) as User;
        set({ token, refreshToken, user });
      } catch {
        localStorage.removeItem("skep_token");
        localStorage.removeItem("skep_refresh_token");
        localStorage.removeItem("skep_user");
      }
    }
  },
}));
