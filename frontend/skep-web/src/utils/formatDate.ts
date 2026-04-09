import { format, parseISO } from "date-fns";
import { ko } from "date-fns/locale";

/**
 * Format a date string or Date object to "yyyy-MM-dd" (or custom pattern).
 * Returns "-" for null/undefined values.
 */
export function formatDate(
  date: string | Date | null | undefined,
  pattern: string = "yyyy-MM-dd"
): string {
  if (!date) return "-";
  try {
    const d = typeof date === "string" ? parseISO(date) : date;
    return format(d, pattern, { locale: ko });
  } catch {
    return "-";
  }
}

/**
 * Format a date with time: "yyyy-MM-dd HH:mm"
 */
export function formatDateTime(
  date: string | Date | null | undefined
): string {
  return formatDate(date, "yyyy-MM-dd HH:mm");
}

/**
 * Format a number as Korean Won currency: "1,234,567원"
 */
export function formatMoney(amount: number | null | undefined): string {
  if (amount == null) return "-";
  return `${amount.toLocaleString("ko-KR")}원`;
}

/**
 * Format a phone number: "010-1234-5678"
 */
export function formatPhone(phone: string | null | undefined): string {
  if (!phone) return "-";
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 11) {
    return `${cleaned.slice(0, 3)}-${cleaned.slice(3, 7)}-${cleaned.slice(7)}`;
  }
  if (cleaned.length === 10) {
    return `${cleaned.slice(0, 3)}-${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  return phone;
}
