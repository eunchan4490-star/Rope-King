import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import type { OrderWithItem, OrderStatus } from "@/lib/types";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "확인 대기중",
  approved: "지급 완료",
  rejected: "거절됨",
};

const STATUS_STYLE: Record<OrderStatus, string> = {
  pending: "bg-yellow-500/20 text-yellow-300",
  approved: "bg-green-500/20 text-brand-accent",
  rejected: "bg-red-500/20 text-brand-danger",
};

export default async function OrdersPage() {
  const user = await getCurrentUser();
  if (!user) {
    redirect("/login");
  }

  const supabase = await createClient();
  // RLS restricts this to the signed-in user's own orders regardless of
  // what's queried for — see supabase/schema.sql's orders_select_own policy.
  const { data: orders, error } = await supabase
    .from("orders")
    .select("id, item_id, price, status, created_at, approved_at, items(id, name, image_url)")
    .order("created_at", { ascending: false });

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-bold text-brand-gold">내 주문 내역</h1>

      {error && (
        <p className="text-sm text-brand-danger">
          주문 내역을 불러오지 못했습니다: {error.message}
        </p>
      )}

      {!error && (!orders || orders.length === 0) && (
        <p className="text-sm text-white/60">아직 신청한 주문이 없습니다.</p>
      )}

      <div className="flex flex-col gap-3">
        {(orders as unknown as OrderWithItem[] | null)?.map((order) => (
          <Link
            key={order.id}
            href={`/orders/${order.id}`}
            className="flex items-center justify-between rounded-lg bg-brand-panel p-3 hover:bg-white/10"
          >
            <div>
              <p className="font-semibold">{order.items?.name ?? order.item_id}</p>
              <p className="text-xs text-white/50">
                {new Date(order.created_at).toLocaleString("ko-KR")}
              </p>
            </div>
            <div className="flex flex-col items-end gap-1">
              <span className="text-sm text-brand-gold">
                {order.price.toLocaleString()}원
              </span>
              <span
                className={`rounded px-2 py-0.5 text-xs ${STATUS_STYLE[order.status]}`}
              >
                {STATUS_LABEL[order.status]}
              </span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
