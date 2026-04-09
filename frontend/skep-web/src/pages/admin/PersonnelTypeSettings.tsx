import { Shield, Truck, HardHat } from "lucide-react";

const PERSONNEL_TYPES = [
  {
    key: "DRIVER",
    label: "운전원",
    description: "장비를 직접 운전하는 인원. 운전면허 및 관련 자격증 필요.",
    icon: Truck,
    color: "bg-blue-100 text-blue-600",
  },
  {
    key: "GUIDE",
    label: "유도원",
    description:
      "장비 이동 시 유도 및 안전 관리를 담당하는 인원. 안전교육 이수 필수.",
    icon: HardHat,
    color: "bg-green-100 text-green-600",
  },
  {
    key: "SAFETY_INSPECTOR",
    label: "안전 점검관",
    description:
      "현장 안전 점검을 수행하는 인원. 산업안전 자격 또는 관련 경력 필요.",
    icon: Shield,
    color: "bg-purple-100 text-purple-600",
  },
];

export default function PersonnelTypeSettings() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">인원 유형 설정</h1>
        <p className="mt-1 text-sm text-gray-500">
          시스템에 정의된 인원 유형입니다. 이 값들은 시스템에서 관리되며 수정할
          수 없습니다.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {PERSONNEL_TYPES.map((pt) => {
          const Icon = pt.icon;
          return (
            <div
              key={pt.key}
              className="rounded-xl border border-gray-200 bg-white p-6"
            >
              <div className="flex items-center gap-3">
                <div className={`rounded-lg p-2.5 ${pt.color}`}>
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">{pt.label}</p>
                  <p className="text-xs text-gray-400">{pt.key}</p>
                </div>
              </div>
              <p className="mt-4 text-sm text-gray-600">{pt.description}</p>
              <div className="mt-4">
                <span className="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-600">
                  시스템 정의
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
