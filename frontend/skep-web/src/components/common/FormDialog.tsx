import { useEffect, useRef } from "react";
import { X, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";

interface FormDialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  onSave?: () => void;
  saveLabel?: string;
  cancelLabel?: string;
  isSaving?: boolean;
  /** Hide footer buttons (useful when form has its own submit) */
  hideFooter?: boolean;
  className?: string;
}

export function FormDialog({
  open,
  onClose,
  title,
  children,
  onSave,
  saveLabel = "저장",
  cancelLabel = "취소",
  isSaving = false,
  hideFooter = false,
  className,
}: FormDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (open) {
      if (!dialog.open) dialog.showModal();
    } else {
      if (dialog.open) dialog.close();
    }
  }, [open]);

  // Close on backdrop click
  const handleBackdropClick = (e: React.MouseEvent<HTMLDialogElement>) => {
    if (e.target === dialogRef.current) {
      onClose();
    }
  };

  // Close on Escape
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    const handleCancel = (e: Event) => {
      e.preventDefault();
      onClose();
    };
    dialog.addEventListener("cancel", handleCancel);
    return () => dialog.removeEventListener("cancel", handleCancel);
  }, [onClose]);

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className={cn(
        "m-auto w-full max-w-lg rounded-xl bg-white p-0 shadow-xl",
        "backdrop:bg-black/50",
        className
      )}
    >
      {/* Header */}
      <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
        <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      {/* Body */}
      <div className="px-6 py-4">{children}</div>

      {/* Footer */}
      {!hideFooter && (
        <div className="flex items-center justify-end gap-3 border-t border-gray-200 px-6 py-4">
          <button
            type="button"
            onClick={onClose}
            disabled={isSaving}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          {onSave && (
            <button
              type="button"
              onClick={onSave}
              disabled={isSaving}
              className={cn(
                "flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white",
                "hover:bg-blue-700 transition-colors disabled:opacity-50"
              )}
            >
              {isSaving && <Loader2 className="h-4 w-4 animate-spin" />}
              {saveLabel}
            </button>
          )}
        </div>
      )}
    </dialog>
  );
}
