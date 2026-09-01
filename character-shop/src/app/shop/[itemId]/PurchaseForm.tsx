"use client";

import { useFormState, useFormStatus } from "react-dom";
import { createOrderAction, type CreateOrderState } from "./actions";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="w-full rounded-lg bg-brand-gold px-4 py-3 font-semibold text-black disabled:opacity-60"
    >
      {pending ? "신청 중..." : "구매 신청하기"}
    </button>
  );
}

export default function PurchaseForm({ itemId }: { itemId: string }) {
  const action = createOrderAction.bind(null, itemId);
  const initialState: CreateOrderState = { error: null };
  const [state, formAction] = useFormState(action, initialState);

  return (
    <form action={formAction} className="flex flex-col gap-3">
      <label className="flex flex-col gap-1 text-sm">
        입금자명
        <input
          name="depositor_name"
          required
          maxLength={40}
          placeholder="입금하실 분 성함"
          className="rounded bg-black/30 px-3 py-2 text-white placeholder:text-white/40"
        />
      </label>
      {state.error && (
        <p className="text-sm text-brand-danger">{state.error}</p>
      )}
      <SubmitButton />
    </form>
  );
}
