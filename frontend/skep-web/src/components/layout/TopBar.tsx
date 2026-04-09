import { useState, useRef, useEffect } from "react";
import { useLocation } from "react-router-dom";
import { Bell, ChevronDown, User as UserIcon } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { cn } from "@/lib/utils";
import { useAuth } from "@/hooks/useAuth";
import { notificationsApi, queryKeys } from "@/api/endpoints";

// Route path -> page title (Korean)
const PAGE_TITLES: Record<string, string> = {
  "/": "대시보드",
  "/companies": "업체 관리",
  "/equipment": "장비 관리",
  "/equipment/persons": "인력 관리",
  "/equipment/types": "장비 유형",
  "/documents": "문서 관리",
  "/dispatch/plans": "배치 계획",
  "/dispatch/rosters": "일일 배치표",
  "/dispatch/work-records": "작업 기록",
  "/dispatch/sites": "현장 관리",
  "/dispatch/quotations": "견적 관리",
  "/dispatch/checklists": "배치 체크리스트",
  "/inspection/safety": "안전 점검",
  "/inspection/maintenance": "정비 이력",
  "/settlement": "정산 관리",
  "/notifications": "알림",
  "/users": "사용자 관리",
};

export function TopBar() {
  const location = useLocation();
  const { user, logout } = useAuth();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const pageTitle =
    PAGE_TITLES[location.pathname] ?? "SKEP";

  const { data: unreadData } = useQuery({
    queryKey: queryKeys.notifications.unreadCount,
    queryFn: () => notificationsApi.unreadCount(),
    refetchInterval: 60_000, // poll every 60s
  });

  const unreadCount = unreadData?.count ?? 0;

  // Close dropdown on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target as Node)
      ) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  return (
    <header className="flex h-16 shrink-0 items-center justify-between border-b border-gray-200 bg-white px-6">
      {/* Left: Page title */}
      <h1 className="text-lg font-semibold text-gray-900">{pageTitle}</h1>

      {/* Right: Notifications + User dropdown */}
      <div className="flex items-center gap-4">
        {/* Notification bell */}
        <button
          type="button"
          className="relative rounded-lg p-2 text-gray-500 hover:bg-gray-100 transition-colors"
          aria-label="알림"
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-0.5 -right-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white">
              {unreadCount > 99 ? "99+" : unreadCount}
            </span>
          )}
        </button>

        {/* User dropdown */}
        <div className="relative" ref={dropdownRef}>
          <button
            type="button"
            onClick={() => setDropdownOpen(!dropdownOpen)}
            className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 transition-colors"
          >
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-200">
              <UserIcon className="h-4 w-4 text-gray-600" />
            </div>
            <span className="hidden sm:block font-medium">
              {user?.name ?? ""}
            </span>
            <ChevronDown className="h-4 w-4 text-gray-400" />
          </button>

          {dropdownOpen && (
            <div className="absolute right-0 top-full mt-1 w-48 rounded-lg border border-gray-200 bg-white py-1 shadow-lg z-50">
              <div className="border-b border-gray-100 px-4 py-2">
                <p className="text-sm font-medium text-gray-900">
                  {user?.name}
                </p>
                <p className="text-xs text-gray-500">{user?.email}</p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setDropdownOpen(false);
                  logout();
                }}
                className={cn(
                  "w-full px-4 py-2 text-left text-sm text-gray-700",
                  "hover:bg-gray-100 transition-colors"
                )}
              >
                로그아웃
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
