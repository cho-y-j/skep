import { useQuery } from "@tanstack/react-query";
import {
  Truck,
  Users,
  CalendarDays,
  AlertTriangle,
  Clock,
} from "lucide-react";
import {
  equipmentApi,
  plansApi,
  documentsApi,
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

export default function SupplierDashboard() {
  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 1 }),
    queryFn: () => equipmentApi.getAll({ size: 1 }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 1 }),
    queryFn: () => equipmentApi.getPersons({ size: 1 }),
  });

  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({ size: 5, sort: "createdAt,desc" }),
    queryFn: () => plansApi.getAll({ size: 5, sort: "createdAt,desc" }),
  });

  const expiringQuery = useQuery({
    queryKey: queryKeys.documents.expiring(30),
    queryFn: () => documentsApi.getExpiring(30),
  });

  const stats = [
    {
      title: "보유 장비",
      value: equipmentQuery.data?.totalElements ?? 0,
      icon: Truck,
      color: "bg-blue-600",
      isLoading: equipmentQuery.isLoading,
    },
    {
      title: "등록 인력",
      value: personsQuery.data?.totalElements ?? 0,
      icon: Users,
      color: "bg-green-600",
      isLoading: personsQuery.isLoading,
    },
    {
      title: "배치 현황",
      value: plansQuery.data?.totalElements ?? 0,
      icon: CalendarDays,
      color: "bg-purple-600",
      isLoading: plansQuery.isLoading,
    },
  ];

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">공급사 대시보드</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {stats.map((s) => (
          <StatCard key={s.title} {...s} />
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Pending requests */}
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <div className="mb-4 flex items-center gap-2">
            <Clock className="h-5 w-5 text-gray-500" />
            <h2 className="text-lg font-semibold text-gray-900">
              대기중 요청
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
                  대기중 요청이 없습니다.
                </li>
              )}
            </ul>
          )}
        </div>

        {/* Expiring documents */}
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <div className="mb-4 flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-amber-500" />
            <h2 className="text-lg font-semibold text-gray-900">
              만료 예정 서류 (30일 이내)
            </h2>
          </div>
          {expiringQuery.isLoading ? (
            <p className="text-sm text-gray-500">불러오는 중...</p>
          ) : (
            <ul className="divide-y divide-gray-100">
              {(expiringQuery.data ?? []).slice(0, 5).map((doc) => (
                <li
                  key={doc.id}
                  className="flex items-center justify-between py-3"
                >
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      {doc.typeName}
                    </p>
                    <p className="text-xs text-gray-500">{doc.ownerName}</p>
                  </div>
                  <p className="text-sm text-amber-600">
                    {formatDate(doc.expiryDate)}
                  </p>
                </li>
              ))}
              {(expiringQuery.data ?? []).length === 0 && (
                <li className="py-4 text-center text-sm text-gray-500">
                  만료 예정 서류가 없습니다.
                </li>
              )}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
