import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import {
  Bell,
  CheckCheck,
  Send,
  Mail,
  MailOpen,
} from "lucide-react";
import { notificationsApi, authApi, queryKeys } from "@/api/endpoints";
import type { Notification } from "@/types";
import { FormDialog } from "@/components/common/FormDialog";
import { formatDate } from "@/utils/formatDate";

const sendSchema = z.object({
  userId: z.string().min(1, "수신자를 선택하세요"),
  title: z.string().min(1, "제목을 입력하세요"),
  message: z.string().min(1, "내용을 입력하세요"),
  type: z.string().optional(),
});

type SendFormValues = z.infer<typeof sendSchema>;

export default function Notifications() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  const notiQuery = useQuery({
    queryKey: queryKeys.notifications.all({ size: 100 }),
    queryFn: () => notificationsApi.getAll({ size: 100 }),
  });

  const usersQuery = useQuery({
    queryKey: queryKeys.auth.users({ size: 200 }),
    queryFn: () => authApi.getUsers({ size: 200 }),
  });

  const markReadMutation = useMutation({
    mutationFn: (id: string) => notificationsApi.markRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });

  const markAllReadMutation = useMutation({
    mutationFn: () => notificationsApi.markAllRead(),
    onSuccess: () => {
      toast.success("모든 알림을 읽음 처리했습니다.");
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });

  const sendMutation = useMutation({
    mutationFn: (data: SendFormValues) => notificationsApi.sendMessage(data),
    onSuccess: () => {
      toast.success("메시지가 발송되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("메시지 발송에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SendFormValues>({
    resolver: zodResolver(sendSchema),
  });

  const notifications = notiQuery.data?.content ?? [];
  const unreadCount = notifications.filter((n) => !n.read).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">알림 관리</h1>
          {unreadCount > 0 && (
            <span className="rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-700">
              {unreadCount}건 미읽음
            </span>
          )}
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => markAllReadMutation.mutate()}
            className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
          >
            <CheckCheck className="h-4 w-4" />
            모두 읽음
          </button>
          <button
            type="button"
            onClick={() => {
              reset();
              setDialogOpen(true);
            }}
            className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            <Send className="h-4 w-4" />
            메시지 발송
          </button>
        </div>
      </div>

      {notiQuery.isLoading && (
        <p className="text-sm text-gray-500">불러오는 중...</p>
      )}

      <div className="space-y-2">
        {notifications.map((noti) => (
          <div
            key={noti.id}
            className={`rounded-xl border p-4 transition-colors ${
              noti.read
                ? "border-gray-200 bg-white"
                : "border-blue-200 bg-blue-50"
            }`}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-start gap-3">
                <div
                  className={`mt-0.5 rounded-lg p-2 ${
                    noti.read
                      ? "bg-gray-100 text-gray-400"
                      : "bg-blue-100 text-blue-600"
                  }`}
                >
                  {noti.read ? (
                    <MailOpen className="h-4 w-4" />
                  ) : (
                    <Mail className="h-4 w-4" />
                  )}
                </div>
                <div>
                  <p
                    className={`text-sm font-medium ${
                      noti.read ? "text-gray-600" : "text-gray-900"
                    }`}
                  >
                    {noti.title}
                  </p>
                  <p className="mt-0.5 text-sm text-gray-500">{noti.message}</p>
                  <div className="mt-1 flex items-center gap-2 text-xs text-gray-400">
                    <span>{formatDate(noti.createdAt, "yyyy-MM-dd HH:mm")}</span>
                    {noti.type && (
                      <span className="rounded bg-gray-100 px-1.5 py-0.5">
                        {noti.type}
                      </span>
                    )}
                  </div>
                </div>
              </div>
              {!noti.read && (
                <button
                  type="button"
                  onClick={() => markReadMutation.mutate(noti.id)}
                  className="text-xs text-blue-600 hover:underline"
                >
                  읽음
                </button>
              )}
            </div>
          </div>
        ))}
        {notifications.length === 0 && !notiQuery.isLoading && (
          <div className="flex flex-col items-center py-16 text-gray-400">
            <Bell className="mb-2 h-10 w-10" />
            <p className="text-sm">알림이 없습니다.</p>
          </div>
        )}
      </div>

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="메시지 발송"
        onSave={handleSubmit((data) => sendMutation.mutate(data))}
        isSaving={sendMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              수신자
            </label>
            <select
              {...register("userId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(usersQuery.data?.content ?? []).map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name} ({u.email})
                </option>
              ))}
            </select>
            {errors.userId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.userId.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              제목
            </label>
            <input
              {...register("title")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.title && (
              <p className="mt-1 text-xs text-red-500">
                {errors.title.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              내용
            </label>
            <textarea
              {...register("message")}
              rows={4}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.message && (
              <p className="mt-1 text-xs text-red-500">
                {errors.message.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              유형 (선택)
            </label>
            <select
              {...register("type")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">일반</option>
              <option value="SYSTEM">시스템</option>
              <option value="ALERT">경고</option>
              <option value="INFO">안내</option>
            </select>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
