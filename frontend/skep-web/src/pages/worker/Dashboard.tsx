import { useNavigate } from "react-router-dom";
import {
  Clock,
  FileSignature,
  Shield,
  Wrench,
  MapPin,
} from "lucide-react";
import { useAuth } from "@/hooks/useAuth";

const QUICK_ACTIONS = [
  {
    label: "출근 기록",
    icon: Clock,
    path: "/worker/attendance",
    color: "bg-green-600",
    roles: ["DRIVER", "INSPECTOR"],
  },
  {
    label: "작업 확인서",
    icon: FileSignature,
    path: "/worker/work-confirmation",
    color: "bg-blue-600",
    roles: ["DRIVER"],
  },
  {
    label: "안전 점검",
    icon: Shield,
    path: "/worker/safety-inspection",
    color: "bg-purple-600",
    roles: ["INSPECTOR", "DRIVER"],
  },
  {
    label: "정비 점검",
    icon: Wrench,
    path: "/worker/maintenance",
    color: "bg-orange-600",
    roles: ["DRIVER"],
  },
  {
    label: "위치 확인",
    icon: MapPin,
    path: "/worker/location",
    color: "bg-indigo-600",
    roles: ["DRIVER", "INSPECTOR"],
  },
];

export default function WorkerDashboard() {
  const navigate = useNavigate();
  const { user } = useAuth();

  const filteredActions = QUICK_ACTIONS.filter(
    (a) => !user?.role || a.roles.includes(user.role)
  );

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          안녕하세요, {user?.name ?? "작업자"}님
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          오늘도 안전한 하루 되세요.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {filteredActions.map((action) => {
          const Icon = action.icon;
          return (
            <button
              key={action.path}
              type="button"
              onClick={() => navigate(action.path)}
              className="flex items-center gap-4 rounded-xl border border-gray-200 bg-white p-6 text-left transition-colors hover:bg-gray-50"
            >
              <div className={`rounded-lg p-3 ${action.color}`}>
                <Icon className="h-6 w-6 text-white" />
              </div>
              <span className="text-lg font-medium text-gray-900">
                {action.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
