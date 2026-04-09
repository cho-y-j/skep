import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import {
  CreditCard,
  Building2,
  Truck,
  Users,
  Search,
  CheckCircle,
  XCircle,
  Loader2,
} from "lucide-react";
import { equipmentApi, queryKeys } from "@/api/endpoints";
import client from "@/api/client";

// Tab types
type TabKey = "driver_license" | "business" | "cargo" | "batch";

const TABS: { key: TabKey; label: string; icon: React.ElementType }[] = [
  { key: "driver_license", label: "운전면허", icon: CreditCard },
  { key: "business", label: "사업자등록", icon: Building2 },
  { key: "cargo", label: "화물운송", icon: Truck },
  { key: "batch", label: "일괄 검증", icon: Users },
];

// Schemas
const driverLicenseSchema = z.object({
  licenseNumber: z.string().min(1, "면허번호를 입력하세요"),
  name: z.string().min(1, "이름을 입력하세요"),
  birthDate: z.string().min(1, "생년월일을 입력하세요"),
});

const businessSchema = z.object({
  businessNumber: z.string().min(1, "사업자번호를 입력하세요"),
});

const cargoSchema = z.object({
  permitNumber: z.string().min(1, "허가번호를 입력하세요"),
  vehicleNumber: z.string().min(1, "차량번호를 입력하세요"),
});

type DriverLicenseValues = z.infer<typeof driverLicenseSchema>;
type BusinessValues = z.infer<typeof businessSchema>;
type CargoValues = z.infer<typeof cargoSchema>;

interface VerifyResult {
  valid: boolean;
  message: string;
  details?: Record<string, string>;
}

// Simulated verify API (replace with real endpoint when available)
async function verifyDriverLicense(data: DriverLicenseValues): Promise<VerifyResult> {
  return client.post("/api/verification/driver-license", data);
}

async function verifyBusiness(data: BusinessValues): Promise<VerifyResult> {
  return client.post("/api/verification/business", data);
}

async function verifyCargo(data: CargoValues): Promise<VerifyResult> {
  return client.post("/api/verification/cargo", data);
}

async function batchVerifyDrivers(): Promise<{ total: number; verified: number; failed: number }> {
  return client.post("/api/verification/batch/drivers");
}

function ResultCard({ result }: { result: VerifyResult | null }) {
  if (!result) return null;
  return (
    <div
      className={`mt-4 rounded-xl border p-4 ${
        result.valid
          ? "border-green-200 bg-green-50"
          : "border-red-200 bg-red-50"
      }`}
    >
      <div className="flex items-center gap-2">
        {result.valid ? (
          <CheckCircle className="h-5 w-5 text-green-600" />
        ) : (
          <XCircle className="h-5 w-5 text-red-600" />
        )}
        <span
          className={`font-medium ${
            result.valid ? "text-green-800" : "text-red-800"
          }`}
        >
          {result.valid ? "검증 성공" : "검증 실패"}
        </span>
      </div>
      <p className="mt-1 text-sm text-gray-600">{result.message}</p>
      {result.details && (
        <div className="mt-3 space-y-1">
          {Object.entries(result.details).map(([key, val]) => (
            <div key={key} className="flex text-xs">
              <span className="w-24 text-gray-500">{key}</span>
              <span className="text-gray-700">{val}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function Verification() {
  const [tab, setTab] = useState<TabKey>("driver_license");
  const [dlResult, setDlResult] = useState<VerifyResult | null>(null);
  const [bizResult, setBizResult] = useState<VerifyResult | null>(null);
  const [cargoResult, setCargoResult] = useState<VerifyResult | null>(null);
  const [batchProgress, setBatchProgress] = useState(0);
  const [batchResult, setBatchResult] = useState<{
    total: number;
    verified: number;
    failed: number;
  } | null>(null);

  // Forms
  const dlForm = useForm<DriverLicenseValues>({
    resolver: zodResolver(driverLicenseSchema),
  });
  const bizForm = useForm<BusinessValues>({
    resolver: zodResolver(businessSchema),
  });
  const cargoForm = useForm<CargoValues>({
    resolver: zodResolver(cargoSchema),
  });

  // Persons query for batch
  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 200, role: "DRIVER" }),
    queryFn: () => equipmentApi.getPersons({ size: 200, role: "DRIVER" }),
    enabled: tab === "batch",
  });

  // Mutations
  const dlMutation = useMutation({
    mutationFn: verifyDriverLicense,
    onSuccess: (data) => {
      setDlResult(data);
      toast.success("검증이 완료되었습니다.");
    },
    onError: () => toast.error("검증 요청에 실패했습니다."),
  });

  const bizMutation = useMutation({
    mutationFn: verifyBusiness,
    onSuccess: (data) => {
      setBizResult(data);
      toast.success("검증이 완료되었습니다.");
    },
    onError: () => toast.error("검증 요청에 실패했습니다."),
  });

  const cargoMutation = useMutation({
    mutationFn: verifyCargo,
    onSuccess: (data) => {
      setCargoResult(data);
      toast.success("검증이 완료되었습니다.");
    },
    onError: () => toast.error("검증 요청에 실패했습니다."),
  });

  const batchMutation = useMutation({
    mutationFn: async () => {
      const drivers = personsQuery.data?.content ?? [];
      const total = drivers.length;
      let verified = 0;
      let failed = 0;

      for (let i = 0; i < total; i++) {
        try {
          await verifyDriverLicense({
            licenseNumber: "",
            name: drivers[i].name,
            birthDate: "",
          });
          verified += 1;
        } catch {
          failed += 1;
        }
        setBatchProgress(Math.round(((i + 1) / total) * 100));
      }
      return { total, verified, failed };
    },
    onSuccess: (data) => {
      setBatchResult(data);
      toast.success("일괄 검증이 완료되었습니다.");
    },
    onError: () => toast.error("일괄 검증에 실패했습니다."),
  });

  const inputClass =
    "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500";
  const btnClass =
    "flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50";

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">자격 검증</h1>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        {TABS.map((t) => {
          const Icon = t.icon;
          return (
            <button
              key={t.key}
              type="button"
              onClick={() => setTab(t.key)}
              className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium transition-colors ${
                tab === t.key
                  ? "border-b-2 border-blue-600 text-blue-600"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <Icon className="h-4 w-4" />
              {t.label}
            </button>
          );
        })}
      </div>

      {/* Driver License */}
      {tab === "driver_license" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            운전면허 검증
          </h2>
          <form
            className="space-y-4"
            onSubmit={dlForm.handleSubmit((data) => {
              setDlResult(null);
              dlMutation.mutate(data);
            })}
          >
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                면허번호
              </label>
              <input
                {...dlForm.register("licenseNumber")}
                className={inputClass}
                placeholder="12-34-567890-12"
              />
              {dlForm.formState.errors.licenseNumber && (
                <p className="mt-1 text-xs text-red-500">
                  {dlForm.formState.errors.licenseNumber.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                성명
              </label>
              <input
                {...dlForm.register("name")}
                className={inputClass}
              />
              {dlForm.formState.errors.name && (
                <p className="mt-1 text-xs text-red-500">
                  {dlForm.formState.errors.name.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                생년월일
              </label>
              <input
                type="date"
                {...dlForm.register("birthDate")}
                className={inputClass}
              />
              {dlForm.formState.errors.birthDate && (
                <p className="mt-1 text-xs text-red-500">
                  {dlForm.formState.errors.birthDate.message}
                </p>
              )}
            </div>
            <button type="submit" disabled={dlMutation.isPending} className={btnClass}>
              {dlMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Search className="h-4 w-4" />
              )}
              검증하기
            </button>
          </form>
          <ResultCard result={dlResult} />
        </div>
      )}

      {/* Business Registration */}
      {tab === "business" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            사업자등록 검증
          </h2>
          <form
            className="space-y-4"
            onSubmit={bizForm.handleSubmit((data) => {
              setBizResult(null);
              bizMutation.mutate(data);
            })}
          >
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                사업자번호
              </label>
              <input
                {...bizForm.register("businessNumber")}
                className={inputClass}
                placeholder="123-45-67890"
              />
              {bizForm.formState.errors.businessNumber && (
                <p className="mt-1 text-xs text-red-500">
                  {bizForm.formState.errors.businessNumber.message}
                </p>
              )}
            </div>
            <button type="submit" disabled={bizMutation.isPending} className={btnClass}>
              {bizMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Search className="h-4 w-4" />
              )}
              검증하기
            </button>
          </form>
          <ResultCard result={bizResult} />
        </div>
      )}

      {/* Cargo */}
      {tab === "cargo" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            화물운송 검증
          </h2>
          <form
            className="space-y-4"
            onSubmit={cargoForm.handleSubmit((data) => {
              setCargoResult(null);
              cargoMutation.mutate(data);
            })}
          >
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                허가번호
              </label>
              <input
                {...cargoForm.register("permitNumber")}
                className={inputClass}
              />
              {cargoForm.formState.errors.permitNumber && (
                <p className="mt-1 text-xs text-red-500">
                  {cargoForm.formState.errors.permitNumber.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                차량번호
              </label>
              <input
                {...cargoForm.register("vehicleNumber")}
                className={inputClass}
              />
              {cargoForm.formState.errors.vehicleNumber && (
                <p className="mt-1 text-xs text-red-500">
                  {cargoForm.formState.errors.vehicleNumber.message}
                </p>
              )}
            </div>
            <button type="submit" disabled={cargoMutation.isPending} className={btnClass}>
              {cargoMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Search className="h-4 w-4" />
              )}
              검증하기
            </button>
          </form>
          <ResultCard result={cargoResult} />
        </div>
      )}

      {/* Batch */}
      {tab === "batch" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            일괄 검증
          </h2>
          <p className="mb-4 text-sm text-gray-600">
            등록된 운전원의 자격을 일괄 검증합니다.
          </p>

          <div className="mb-4 rounded-lg bg-gray-50 p-4">
            <p className="text-sm text-gray-700">
              등록 운전원:{" "}
              <span className="font-bold">
                {personsQuery.isLoading
                  ? "..."
                  : personsQuery.data?.totalElements ?? 0}
              </span>
              명
            </p>
          </div>

          <button
            type="button"
            onClick={() => {
              setBatchProgress(0);
              setBatchResult(null);
              batchMutation.mutate();
            }}
            disabled={
              batchMutation.isPending ||
              (personsQuery.data?.totalElements ?? 0) === 0
            }
            className={btnClass}
          >
            {batchMutation.isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Users className="h-4 w-4" />
            )}
            일괄 검증 시작
          </button>

          {/* Progress */}
          {batchMutation.isPending && (
            <div className="mt-4">
              <div className="mb-1 flex justify-between text-xs text-gray-500">
                <span>진행 중...</span>
                <span>{batchProgress}%</span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-gray-200">
                <div
                  className="h-full rounded-full bg-blue-600 transition-all"
                  style={{ width: `${batchProgress}%` }}
                />
              </div>
            </div>
          )}

          {/* Batch result */}
          {batchResult && (
            <div className="mt-4 rounded-xl border border-gray-200 bg-gray-50 p-4">
              <h3 className="mb-2 text-sm font-semibold text-gray-700">
                검증 결과
              </h3>
              <div className="grid grid-cols-3 gap-4 text-center">
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {batchResult.total}
                  </p>
                  <p className="text-xs text-gray-500">전체</p>
                </div>
                <div>
                  <p className="text-2xl font-bold text-green-600">
                    {batchResult.verified}
                  </p>
                  <p className="text-xs text-gray-500">성공</p>
                </div>
                <div>
                  <p className="text-2xl font-bold text-red-600">
                    {batchResult.failed}
                  </p>
                  <p className="text-xs text-gray-500">실패</p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
