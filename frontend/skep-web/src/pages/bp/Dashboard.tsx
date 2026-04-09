import { useQuery } from "@tanstack/react-query";
import {
  CalendarDays,
  Users,
  Shield,
  Wallet,
  Clock,
} from "lucide-react";
import {
  plansApi,
  equipmentApi,
  safetyApi,
  settlementApi,
  queryKeys,
} from "@/api/endpoints";
import { formatDate } from "@/utils/formatDate";
import { StatusBadge } from "@/components/common/StatusBadge";

function StatCard({
  title,
  value,
  icon: Icon,
  color,
  isLoading,
}: {
  title: string;
  value: number;
  icon: React.ElementType;
  color: string;
  isLoading: boolean;
}) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{title}</p>
          <p className="mt-1 text-3xl font-bold text-gray-900">
            {isLoading ? "-" : value.toLocaleString()}
          </p>
        </div>
        <div className={`rounded-lg p-3 ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
      </div>
    </div>
  );
}

export default function BpDashboard() {
  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({ size: 5, sort: "createdAt,desc" }),
    queryFn: () => plansApi.getAll({ size: 5, sort: "createdAt,desc" }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 1 }),
    queryFn: () => equipmentApi.getPersons({ size: 1 }),
  });

  const safetyQuery = useQuery({
    queryKey: queryKeys.inspection.safety({ size: 1 }),
    queryFn: () => safetyApi.getAll({ size: 1 }),
  });

  const settlementStatsQuery = useQuery({
    queryKey: queryKeys.settlement.stats,
    queryFn: () => settlementApi.stats(),
  });

  const stats = [
    {
      title: "배치 현황",
      value: plansQuery.data?.totalElements ?? 0,
      icon: CalendarDays,
      color: "bg-blue-600",
      isLoading: plansQuery.isLoading,
    },
    {
      title: "작업 인원",
      value: personsQuery.data?.totalElements ?? 0,
      icon: Users,
      color: "bg-green-600",
      isLoading: personsQuery.isLoading,
    },
    {
      title: "안전 점검",
      value: safetyQuery.data?.totalElements ?? 0,
      icon: Shield,
      color: "bg-purple-600",
      isLoading: safetyQuery.isLoading,
    },
    {
      title: "미정산 건",
      value: settlementStatsQuery.data?.totalOverdue ?? 0,
      icon: Wallet,
      color: "bg-orange-600",
      isLoading: settlementStatsQuery.isLoading,
    },
  ];

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">BP 대시보드</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <StatCard key={s.title} {...s} />
        ))}
      </div>

      {/* Pending approvals */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <div className="mb-4 flex items-center gap-2">
          <Clock className="h-5 w-5 text-gray-500" />
          <h2 className="text-lg font-semibold text-gray-900">
            승인 대기 항목
          </h2>
        </div>
        {plansQuery.isLoading ? (
          <p className="text-sm text-gray-500">불러오는 중...</p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {(plansQuery.data?.content ?? []).map((plan) => (
              <li
                key={plan.id}
                className="flex items-center justify-between py-3"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {plan.siteName}
                  </p>
                  <p className="text-xs text-gray-500">
                    {plan.equipmentName} / {plan.driverName}
                  </p>
                </div>
                <div className="text-right">
                  <StatusBadge status={plan.status} />
                  <p className="mt-1 text-xs text-gray-400">
                    {formatDate(plan.createdAt)}
                  </p>
                </div>
              </li>
            ))}
            {(plansQuery.data?.content ?? []).length === 0 && (
              <li className="py-4 text-center text-sm text-gray-500">
                승인 대기 항목이 없습니다.
              </li>
            )}
          </ul>
        )}
      </div>
    </div>
  );
}
