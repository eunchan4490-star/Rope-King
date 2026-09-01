import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import type { OrderWithItem, OrderStatus } from "@/lib/types";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "확인 대기중",
  approved: "지급 완료",
  rejected: "거절됨",
};

export default async function OrderDetailPage({
  params,
}: {
  params: Promise<{ orderId: string }>;
}) {
  const { orderId } = await params;
  const user = await getCurrentUser();
  if (!user) {
    redirect("/login");
  }

  const supabase = await createClient();
  // RLS already limits this to the caller's own order, but the explicit
  // .eq("user_id", ...) keeps the intent obvious and gives a clean 404
  // instead of relying solely on the policy silently returning no rows.
  const { data: order } = await supabase
    .from("orders")
    .select("id, item_id, price, depositor_name, status, created_at, approved_at, items(id, name, image_url, item_type)")
    .eq("id", orderId)
    .eq("user_id", user.id)
    .single<OrderWithItem>();

  if (!order) {
    notFound();
  }

  // Currency purchases don't grant owned_items — approve_order() instead
  // mints a one-time redeem code the buyer types into the game's "코드
  // 입력" field. RLS limits this to the caller's own codes regardless of
  // the order_id filter here.
  const isCurrencyItem = order.items?.item_type === "currency";
  let redeemCode: { code: string; currency_amount: number } | null = null;
  if (order.status === "approved" && isCurrencyItem) {
    const { data } = await supabase
      .from("redeem_codes")
      .select("code, currency_amount")
      .eq("order_id", order.id)
      .single();
    redeemCode = data;
  }

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-bold text-brand-gold">주문 상세</h1>

      <div className="rounded-lg bg-brand-panel p-4">
        <p className="text-xs text-white/50">주문번호</p>
        <p className="break-all font-mono text-sm">{order.id}</p>

        <div className="mt-3 flex items-center justify-between">
          <span className="font-semibold">{order.items?.name ?? order.item_id}</span>
          <span className="text-brand-gold">{order.price.toLocaleString()}원</span>
        </div>

        <p className="mt-2 text-sm">
          상태: <span className="font-semibold">{STATUS_LABEL[order.status]}</span>
        </p>
        <p className="text-xs text-white/50">
          신청 시간: {new Date(order.created_at).toLocaleString("ko-KR")}
        </p>
        {order.approved_at && (
          <p className="text-xs text-white/50">
            지급 시간: {new Date(order.approved_at).toLocaleString("ko-KR")}
          </p>
        )}
        <p className="mt-2 text-sm">입금자명: {order.depositor_name}</p>
      </div>

      {order.status === "pending" && (
        <div className="rounded-lg border border-brand-gold/40 bg-brand-gold/10 p-4 text-sm">
          <p className="font-semibold text-brand-gold">입금 계좌 안내</p>
          <dl className="mt-2 space-y-1">
            <div className="flex justify-between">
              <dt className="text-white/60">은행</dt>
              <dd>{process.env.DEPOSIT_BANK_NAME}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-white/60">계좌번호</dt>
              <dd className="font-mono">{process.env.DEPOSIT_ACCOUNT_NUMBER}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-white/60">예금주</dt>
              <dd>{process.env.DEPOSIT_ACCOUNT_HOLDER}</dd>
            </div>
          </dl>
          <p className="mt-3 text-xs text-white/60">
            입력하신 입금자명과 실제 입금자명이 같아야 빠르게 확인됩니다.
            <br />
            입금 후 확인까지 시간이 걸릴 수 있습니다.
          </p>
        </div>
      )}

      {order.status === "rejected" && (
        <p className="text-sm text-brand-danger">
          이 주문은 거절되었습니다. 입금 내역 확인이 필요하면 문의해주세요.
        </p>
      )}

      {order.status === "approved" && isCurrencyItem && redeemCode && (
        <div className="rounded-lg border border-brand-accent/40 bg-brand-accent/10 p-4 text-sm">
          <p className="font-semibold text-brand-accent">지급 완료 — 게임에 코드를 입력하세요</p>
          <p className="mt-2 text-xs text-white/60">
            게임 실행 → 설정 → 코드 입력 칸에 아래 코드를 입력하고 확인을
            누르면 {redeemCode.currency_amount}루피가 즉시 지급됩니다.
          </p>
          <p className="mt-3 rounded bg-black/30 px-3 py-2 text-center font-mono text-lg tracking-widest text-brand-accent">
            {redeemCode.code}
          </p>
          <p className="mt-2 text-xs text-white/40">
            코드는 1회만 사용할 수 있습니다.
          </p>
        </div>
      )}

      {order.status === "approved" && !isCurrencyItem && (
        <p className="text-sm text-brand-accent">
          지급이 완료되었습니다. 게임에 같은 계정으로 로그인하면 캐릭터를 사용할 수 있습니다.
        </p>
      )}
    </div>
  );
}
