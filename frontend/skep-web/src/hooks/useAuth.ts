import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useAuthStore } from "@/stores/authStore";
import { authApi } from "@/api/endpoints";
import { UserRole } from "@/types";

export function useAuth() {
  const navigate = useNavigate();
  const { user, token, login: storeLogin, logout: storeLogout } = useAuthStore();

  const isAuthenticated = !!token && !!user;

  const login = useCallback(
    async (email: string, password: string) => {
      const response = await authApi.login({ email, password });
      storeLogin(response);
      return response.user;
    },
    [storeLogin]
  );

  const logout = useCallback(() => {
    authApi.logout().catch(() => {
      // Ignore logout API errors -- clear local state regardless
    });
    storeLogout();
    navigate("/login");
  }, [storeLogout, navigate]);

  const hasRole = useCallback(
    (role: UserRole) => user?.role === role,
    [user]
  );

  const isAdmin = user?.role === UserRole.ADMIN;
  const isSupplier = user?.role === UserRole.SUPPLIER;
  const isBP = user?.role === UserRole.BP;
  const isDriver = user?.role === UserRole.DRIVER;
  const isInspector = user?.role === UserRole.INSPECTOR;
  const isViewer = user?.role === UserRole.VIEWER;

  return {
    user,
    token,
    isAuthenticated,
    login,
    logout,
    hasRole,
    isAdmin,
    isSupplier,
    isBP,
    isDriver,
    isInspector,
    isViewer,
  };
}
