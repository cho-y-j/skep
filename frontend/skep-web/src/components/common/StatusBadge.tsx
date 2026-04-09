import { cn } from "@/lib/utils";
import { getStatusLabel, getStatusColor } from "@/utils/statusLabels";

interface StatusBadgeProps {
  status: string | null | undefined;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const label = getStatusLabel(status);
  const { bg, text } = getStatusColor(status);

  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        bg,
        text,
        className
      )}
    >
      {label}
    </span>
  );
}
