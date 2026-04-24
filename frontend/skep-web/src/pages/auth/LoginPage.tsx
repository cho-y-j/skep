import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { z } from "zod/v4";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2, Eye, EyeOff } from "lucide-react";
import toast from "react-hot-toast";
import { useAuthStore } from "@/stores/authStore";
import { authApi } from "@/api/endpoints";
import { cn } from "@/lib/utils";

const loginSchema = z.object({
  email: z.email("올바른 이메일 주소를 입력하세요."),
  password: z.string().min(4, "비밀번호는 4자 이상이어야 합니다."),
});

type LoginForm = z.infer<typeof loginSchema>;

export function LoginPage() {
  const navigate = useNavigate();
  const storeLogin = useAuthStore((s) => s.login);
  const [showPassword, setShowPassword] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const onSubmit = async (data: LoginForm) => {
    try {
      const response = await authApi.login(data) as any;
      // 서버 응답은 snake_case(access_token/refresh_token) + user 필드 flat
      // 스토어 기대 포맷은 camelCase + user 중첩 → 여기서 변환
      storeLogin({
        token: response.access_token ?? response.token,
        refreshToken: response.refresh_token ?? response.refreshToken,
        user: response.user ?? {
          id: response.user_id,
          email: response.email,
          name: response.name,
          role: response.role,
        },
      });

      toast.success("로그인 성공");

      // Role-based redirect
      navigate("/", { replace: true });
    } catch (err: unknown) {
      const message =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message ?? "로그인에 실패했습니다.";
      toast.error(message);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100 px-4">
      <div className="w-full max-w-md">
        {/* Card */}
        <div className="rounded-2xl bg-white px-8 py-10 shadow-lg">
          {/* Logo */}
          <div className="mb-8 text-center">
            <h1 className="text-3xl font-bold tracking-wider text-gray-900">
              SKEP
            </h1>
            <p className="mt-2 text-sm text-gray-500">
              건설장비 관리 플랫폼
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            {/* Email */}
            <div>
              <label
                htmlFor="email"
                className="mb-1.5 block text-sm font-medium text-gray-700"
              >
                이메일
              </label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                placeholder="email@example.com"
                {...register("email")}
                className={cn(
                  "w-full rounded-lg border px-4 py-2.5 text-sm focus:outline-none focus:ring-2",
                  errors.email
                    ? "border-red-300 focus:ring-red-500"
                    : "border-gray-300 focus:ring-blue-500"
                )}
              />
              {errors.email && (
                <p className="mt-1 text-xs text-red-600">
                  {errors.email.message}
                </p>
              )}
            </div>

            {/* Password */}
            <div>
              <label
                htmlFor="password"
                className="mb-1.5 block text-sm font-medium text-gray-700"
              >
                비밀번호
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  placeholder="비밀번호를 입력하세요"
                  {...register("password")}
                  className={cn(
                    "w-full rounded-lg border px-4 py-2.5 pr-10 text-sm focus:outline-none focus:ring-2",
                    errors.password
                      ? "border-red-300 focus:ring-red-500"
                      : "border-gray-300 focus:ring-blue-500"
                  )}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  tabIndex={-1}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
              {errors.password && (
                <p className="mt-1 text-xs text-red-600">
                  {errors.password.message}
                </p>
              )}
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={isSubmitting}
              className={cn(
                "flex w-full items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white",
                "hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                "transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              )}
            >
              {isSubmitting && <Loader2 className="h-4 w-4 animate-spin" />}
              로그인
            </button>
          </form>
        </div>

        {/* Footer */}
        <p className="mt-6 text-center text-xs text-gray-400">
          SKEP - Construction Equipment Management Platform
        </p>
      </div>
    </div>
  );
}
