"use server";

import { createClient } from "@/lib/supabase/server";

export type SubmitInquiryState = {
  error: string | null;
  success: boolean;
};

/**
 * Saves a contact-form submission via the submit_inquiry RPC (see
 * supabase/schema.sql), which re-validates the message server-side and
 * fans out a Telegram + optional email notification via a database
 * trigger. Works for logged-out visitors too — no auth required.
 */
export async function submitInquiryAction(
  _prevState: SubmitInquiryState,
  formData: FormData
): Promise<SubmitInquiryState> {
  // Honeypot: a real visitor never fills this hidden field in. Silently
  // "succeed" without writing anything so a bot can't tell it was rejected.
  if (String(formData.get("website") ?? "").trim().length > 0) {
    return { error: null, success: true };
  }

  const message = String(formData.get("message") ?? "").trim();
  const contactEmail = String(formData.get("contact_email") ?? "").trim();

  if (!message) {
    return { error: "문의 내용을 입력해주세요.", success: false };
  }
  if (message.length > 2000) {
    return { error: "문의 내용이 너무 깁니다 (2000자 이하로 적어주세요).", success: false };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("submit_inquiry", {
    p_message: message,
    p_contact_email: contactEmail || null,
  });

  if (error) {
    return { error: "문의 전송에 실패했습니다. 잠시 후 다시 시도해주세요.", success: false };
  }

  return { error: null, success: true };
}
