"use client";

import { useFormState, useFormStatus } from "react-dom";
import { submitInquiryAction, type SubmitInquiryState } from "./actions";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="w-full rounded-lg bg-brand-gold px-4 py-3 font-semibold text-black disabled:opacity-60"
    >
      {pending ? "보내는 중..." : "문의 보내기"}
    </button>
  );
}

export default function ContactForm() {
  const initialState: SubmitInquiryState = { error: null, success: false };
  const [state, formAction] = useFormState(submitInquiryAction, initialState);

  if (state.success) {
    return (
      <div className="flex flex-col items-center gap-2 rounded-xl border border-brand-accent/40 bg-brand-accent/10 p-6 text-center">
        <p className="text-2xl">✅</p>
        <p className="text-sm font-semibold text-brand-accent">
          문의가 전송됐어요!
        </p>
        <p className="text-xs text-white/60">
          확인하는 대로 남겨주신 이메일로 답변드릴게요.
        </p>
      </div>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-3">
      <label className="flex flex-col gap-1 text-sm">
        답장 받을 이메일 (선택)
        <input
          name="contact_email"
          type="email"
          maxLength={100}
          placeholder="example@gmail.com"
          className="rounded bg-black/30 px-3 py-2 text-white placeholder:text-white/40"
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        문의 내용
        <textarea
          name="message"
          required
          maxLength={2000}
          rows={6}
          placeholder="궁금한 점이나 문제를 자세히 적어주세요. (예: 어떤 화면에서, 어떤 일이 있었는지)"
          className="resize-none rounded bg-black/30 px-3 py-2 text-white placeholder:text-white/40"
        />
      </label>

      {/* Honeypot — hidden from real visitors via CSS, bots that fill every
          field trip this and the server action quietly no-ops. */}
      <input
        type="text"
        name="website"
        tabIndex={-1}
        autoComplete="off"
        className="absolute left-[-9999px] h-0 w-0 opacity-0"
        aria-hidden="true"
      />

      {state.error && <p className="text-sm text-brand-danger">{state.error}</p>}
      <SubmitButton />
    </form>
  );
}
