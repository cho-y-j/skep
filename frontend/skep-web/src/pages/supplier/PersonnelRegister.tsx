import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { ChevronLeft, ChevronRight, Check, Upload } from "lucide-react";
import toast from "react-hot-toast";
import { equipmentApi, documentsApi, queryKeys } from "@/api/endpoints";

const step1Schema = z.object({
  name: z.string().min(1, "이름을 입력하세요"),
  phone: z.string().min(1, "연락처를 입력하세요"),
  role: z.string().min(1, "역할을 입력하세요"),
  equipmentId: z.string().optional(),
});

type Step1Data = z.infer<typeof step1Schema>;

const STEPS = ["기본 정보", "서류 등록", "확인 및 제출"];

export default function PersonnelRegister() {
  const queryClient = useQueryClient();
  const [step, setStep] = useState(0);
  const [savedBasic, setSavedBasic] = useState<Step1Data | null>(null);
  const [files, setFiles] = useState<File[]>([]);

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<Step1Data>({
    resolver: zodResolver(step1Schema),
    defaultValues: { name: "", phone: "", role: "", equipmentId: "" },
  });

  const createMutation = useMutation({
    mutationFn: async (data: Step1Data) => {
      const person = await equipmentApi.createPerson(data);
      for (const file of files) {
        const fd = new FormData();
        fd.append("file", file);
        fd.append("ownerId", person.id);
        fd.append("ownerType", "PERSON");
        await documentsApi.upload(fd);
      }
      return person;
    },
    onSuccess: () => {
      toast.success("인력이 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["equipment", "persons"] });
    },
    onError: () => {
      toast.error("등록에 실패했습니다.");
    },
  });

  const onStep1Submit = (data: Step1Data) => {
    setSavedBasic(data);
    setStep(1);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles((prev) => [...prev, ...Array.from(e.target.files!)]);
    }
  };

  const handleFinalSubmit = () => {
    if (!savedBasic) return;
    createMutation.mutate(savedBasic);
  };

  return (
    <div className="mx-auto max-w-2xl space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">인력 등록</h1>

      {/* Step indicator */}
      <div className="flex items-center gap-2">
        {STEPS.map((label, i) => (
          <div key={label} className="flex items-center gap-2">
            <div
              className={`flex h-8 w-8 items-center justify-center rounded-full text-sm font-medium ${
                i <= step
                  ? "bg-blue-600 text-white"
                  : "bg-gray-200 text-gray-500"
              }`}
            >
              {i < step ? <Check className="h-4 w-4" /> : i + 1}
            </div>
            <span
              className={`text-sm ${
                i <= step ? "text-gray-900 font-medium" : "text-gray-400"
              }`}
            >
              {label}
            </span>
            {i < STEPS.length - 1 && (
              <div className="mx-2 h-px w-8 bg-gray-300" />
            )}
          </div>
        ))}
      </div>

      {/* Step 1: Basic info */}
      {step === 0 && (
        <form
          onSubmit={handleSubmit(onStep1Submit)}
          className="space-y-4 rounded-xl border border-gray-200 bg-white p-6"
        >
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              이름
            </label>
            <input
              {...register("name")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.name && (
              <p className="mt-1 text-xs text-red-500">{errors.name.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              연락처
            </label>
            <input
              {...register("phone")}
              placeholder="010-0000-0000"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.phone && (
              <p className="mt-1 text-xs text-red-500">{errors.phone.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              역할
            </label>
            <input
              {...register("role")}
              placeholder="운전원, 조수 등"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.role && (
              <p className="mt-1 text-xs text-red-500">{errors.role.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              배정 장비
            </label>
            <select
              {...register("equipmentId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">미배정</option>
              {(equipmentQuery.data?.content ?? []).map((eq) => (
                <option key={eq.id} value={eq.id}>
                  {eq.name} ({eq.model})
                </option>
              ))}
            </select>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
            >
              다음 <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </form>
      )}

      {/* Step 2: Documents */}
      {step === 1 && (
        <div className="space-y-4 rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="text-lg font-semibold text-gray-900">서류 등록</h2>
          <label className="flex cursor-pointer flex-col items-center gap-2 rounded-lg border-2 border-dashed border-gray-300 p-8 text-gray-500 hover:border-blue-400 hover:text-blue-500 transition-colors">
            <Upload className="h-8 w-8" />
            <span className="text-sm">파일을 선택하세요</span>
            <input
              type="file"
              multiple
              className="hidden"
              onChange={handleFileChange}
            />
          </label>
          {files.length > 0 && (
            <ul className="space-y-1">
              {files.map((f, i) => (
                <li
                  key={i}
                  className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2 text-sm"
                >
                  <span className="truncate">{f.name}</span>
                  <button
                    type="button"
                    onClick={() =>
                      setFiles((prev) => prev.filter((_, idx) => idx !== i))
                    }
                    className="text-red-500 hover:text-red-700 text-xs"
                  >
                    삭제
                  </button>
                </li>
              ))}
            </ul>
          )}
          <div className="flex justify-between">
            <button
              type="button"
              onClick={() => setStep(0)}
              className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              <ChevronLeft className="h-4 w-4" /> 이전
            </button>
            <button
              type="button"
              onClick={() => setStep(2)}
              className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
            >
              다음 <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Confirm */}
      {step === 2 && savedBasic && (
        <div className="space-y-4 rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="text-lg font-semibold text-gray-900">확인 및 제출</h2>
          <dl className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <dt className="text-gray-500">이름</dt>
              <dd className="font-medium text-gray-900">{savedBasic.name}</dd>
            </div>
            <div>
              <dt className="text-gray-500">연락처</dt>
              <dd className="font-medium text-gray-900">{savedBasic.phone}</dd>
            </div>
            <div>
              <dt className="text-gray-500">역할</dt>
              <dd className="font-medium text-gray-900">{savedBasic.role}</dd>
            </div>
            <div>
              <dt className="text-gray-500">첨부 서류</dt>
              <dd className="font-medium text-gray-900">{files.length}건</dd>
            </div>
          </dl>
          <div className="flex justify-between">
            <button
              type="button"
              onClick={() => setStep(1)}
              className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              <ChevronLeft className="h-4 w-4" /> 이전
            </button>
            <button
              type="button"
              onClick={handleFinalSubmit}
              disabled={createMutation.isPending}
              className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50"
            >
              {createMutation.isPending ? "등록 중..." : "등록"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
