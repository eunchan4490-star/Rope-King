"use client";

import { useState, useTransition } from "react";
import { approveOrderAction, rejectOrderAction } from "./actions";

export default function OrderRow({
  orderId,
  orderNumber,
  userLabel,
  itemName,
  price,
  depositorName,
  createdAt,
}: {
  orderId: string;
  orderNumber: string;
  userLabel: string;
  itemName: string;
  price: number;
  depositorName: string;
  createdAt: string;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<"approved" | "rejected" | null>(null);

  function handleApprove() {
    setError(null);
    startTransition(async () => {
      const result = await approveOrderAction(orderId);
      if (result.error) {
        setError(result.error);
      } else {
        setDone("approved");
      }
    });
  }

  function handleReject() {
    setError(null);
    startTransition(async () => {
      const result = await rejectOrderAction(orderId);
      if (result.error) {
        setError(result.error);
      } else {
        setDone("rejected");
      }
    });
  }

  return (
    <div className="rounded-lg bg-brand-panel p-3 text-sm">
      <p className="break-all font-mono text-xs text-white/50">
        #{orderNumber}
      </p>
      <div className="mt-1 flex items-center justify-between">
        <span className="font-semibold">{itemName}</span>
        <span className="text-brand-gold">{price.toLocaleString()}원</span>
      </div>
      <p className="mt-1 text-white/70">신청자: {userLabel}</p>
      <p className="text-white/70">입금자명: {depositorName}</p>
      <p className="text-xs text-white/40">
        {new Date(createdAt).toLocaleString("ko-KR")}
      </p>

      {done ? (
        <p
          className={`mt-2 text-sm font-semibold ${done === "approved" ? "text-brand-accent" : "text-brand-danger"}`}
        >
          {done === "approved" ? "승인 완료" : "거절 완료"}
        </p>
      ) : (
        <div className="mt-2 flex gap-2">
          <button
            onClick={handleApprove}
            disabled={isPending}
            className="flex-1 rounded bg-brand-accent px-3 py-2 font-semibold text-black disabled:opacity-60"
          >
            승인
          </button>
          <button
            onClick={handleReject}
            disabled={isPending}
            className="flex-1 rounded bg-brand-danger px-3 py-2 font-semibold text-black disabled:opacity-60"
          >
            거절
          </button>
        </div>
      )}
      {error && <p className="mt-1 text-xs text-brand-danger">{error}</p>}
    </div>
  );
}
