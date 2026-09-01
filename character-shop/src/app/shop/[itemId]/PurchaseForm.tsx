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
          placeholder="예: 홍길동"
          className="rounded bg-black/30 px-3 py-2 text-white placeholder:text-white/40"
        />
        <span className="text-xs font-normal text-white/50">
          송금할 은행 계좌의 <b className="text-white/70">실제 예금주 이름</b>
          을 입력하세요. 은행 앱으로 이체할 때 상대방(저희) 화면에 뜨는
          이름과 똑같아야 확인이 가능해요. (보통 은행 앱에 자동으로 표시되는
          내 이름과 같아요 — 닉네임이나 게임 아이디가 아니에요!)
        </span>
      </label>
      {state.error && (
        <p className="text-sm text-brand-danger">{state.error}</p>
      )}
      <SubmitButton />
    </form>
  );
}
