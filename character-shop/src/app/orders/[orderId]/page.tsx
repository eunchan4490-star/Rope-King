import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import type { OrderWithItem, OrderStatus } from "@/lib/types";
import CopyButton from "@/components/CopyButton";

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
        <div className="flex flex-col gap-2 rounded-lg border-2 border-brand-danger bg-brand-danger/15 p-4 text-center">
          <p className="text-lg font-extrabold leading-snug text-brand-danger">
            ⏰ 지급까지 최대 5시간이
            <br />
            걸릴 수 있어요
          </p>
          <p className="text-base font-bold leading-snug text-brand-danger">
            🌙 자정(00:00) ~ 오전 8시에는
            <br />
            지급이 불가능해요
          </p>
          <p className="text-xs text-white/60">
            사람이 직접 입금 확인 후 승인하는 방식이라 그래요. 급하지 않게
            여유를 갖고 기다려주세요!
          </p>
        </div>
      )}

      {order.status === "pending" && (
        <div className="rounded-lg border border-brand-gold/40 bg-brand-gold/10 p-4 text-sm">
          <p className="font-semibold text-brand-gold">💳 아래 계좌로 입금해주세요</p>
          <p className="mt-2 text-xs text-white/60">
            은행 앱(토스, 카카오뱅크 등)을 열고 계좌번호를 복사해서 붙여넣은
            뒤, 아래 금액과 <b className="text-brand-gold">정확히 똑같이</b>{" "}
            입금해주세요.
          </p>
          <dl className="mt-3 space-y-2">
            <div className="flex items-center justify-between">
              <dt className="text-white/60">은행</dt>
              <dd>{process.env.DEPOSIT_BANK_NAME}</dd>
            </div>
            <div className="flex items-center justify-between">
              <dt className="text-white/60">계좌번호</dt>
              <dd className="flex items-center gap-2">
                <span className="font-mono">{process.env.DEPOSIT_ACCOUNT_NUMBER}</span>
                <CopyButton value={process.env.DEPOSIT_ACCOUNT_NUMBER ?? ""} />
              </dd>
            </div>
            <div className="flex items-center justify-between">
              <dt className="text-white/60">예금주</dt>
              <dd>{process.env.DEPOSIT_ACCOUNT_HOLDER}</dd>
            </div>
            <div className="flex items-center justify-between border-t border-white/10 pt-2">
              <dt className="text-white/60">입금 금액</dt>
              <dd className="text-base font-extrabold text-brand-gold">
                {order.price.toLocaleString()}원
              </dd>
            </div>
            <div className="flex items-center justify-between">
              <dt className="text-white/60">입금자명</dt>
              <dd>{order.depositor_name}</dd>
            </div>
          </dl>
          <p className="mt-3 text-xs text-white/60">
            입력하신 입금자명과 실제 입금자명이 같아야 빠르게 확인돼요.
            <br />
            이 화면을 나가도 괜찮고, 나중에{" "}
            <b className="text-white/80">주문내역</b>에서 다시 확인할 수
            있어요.
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
          <p className="font-semibold text-brand-accent">
            🎁 입금 확인 완료! 아래 코드를 게임에 입력하세요
          </p>
          <div className="mt-3 flex items-center justify-center gap-2 rounded bg-black/30 px-3 py-2">
            <span className="font-mono text-lg tracking-widest text-brand-accent">
              {redeemCode.code}
            </span>
            <CopyButton value={redeemCode.code} />
          </div>
          <ol className="mt-3 flex flex-col gap-1 text-xs text-white/60">
            <li>1. 줄넘킹 게임을 실행하세요.</li>
            <li>2. 타이틀 화면에서 '설정' 버튼을 누르세요.</li>
            <li>3. '코드 입력' 칸에 위 코드를 붙여넣으세요.</li>
            <li>4. 확인을 누르면 {redeemCode.currency_amount}루피가 즉시 지급돼요.</li>
          </ol>
          <p className="mt-2 text-xs text-white/40">
            코드는 1회만 사용할 수 있으니 다른 사람에게 알려주지 마세요.
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
