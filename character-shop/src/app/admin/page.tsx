import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import OrderRow from "./OrderRow";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  const user = await getCurrentUser();
  if (!user) {
    redirect("/login");
  }
  if (!user.isAdmin) {
    // Server-side gate. The real enforcement is Postgres RLS + is_admin()
    // inside approve_order/reject_order — this redirect is just so a
    // non-admin never even sees the page, not the security boundary.
    redirect("/");
  }

  const supabase = await createClient();

  const { data: orders, error } = await supabase
    .from("orders")
    .select("id, user_id, item_id, price, depositor_name, created_at, items(name)")
    .eq("status", "pending")
    .order("created_at", { ascending: true });

  const userIds = Array.from(new Set((orders ?? []).map((o) => o.user_id)));
  const { data: profiles } = userIds.length
    ? await supabase.from("profiles").select("id, email").in("id", userIds)
    : { data: [] as { id: string; email: string | null }[] };

  const emailById = new Map((profiles ?? []).map((p) => [p.id, p.email]));

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-bold text-brand-gold">관리자 · 대기중인 주문</h1>

      {error && (
        <p className="text-sm text-brand-danger">
          주문 목록을 불러오지 못했습니다: {error.message}
        </p>
      )}

      {!error && (!orders || orders.length === 0) && (
        <p className="text-sm text-white/60">대기중인 주문이 없습니다.</p>
      )}

      <div className="flex flex-col gap-3">
        {orders?.map((order) => (
          <OrderRow
            key={order.id}
            orderId={order.id}
            orderNumber={order.id}
            userLabel={emailById.get(order.user_id) ?? order.user_id}
            itemName={
              (order.items as unknown as { name: string } | null)?.name ??
              order.item_id
            }
            price={order.price}
            depositorName={order.depositor_name}
            createdAt={order.created_at}
          />
        ))}
      </div>
    </div>
  );
}
