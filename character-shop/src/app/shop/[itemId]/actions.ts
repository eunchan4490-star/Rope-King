"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type CreateOrderState = {
  error: string | null;
};

/**
 * Creates a purchase order for the signed-in user via the create_order
 * Postgres RPC (see supabase/schema.sql). That function — not this action —
 * is what actually re-reads items.price and stamps auth.uid() server-side,
 * so a tampered client request (or a raw REST/RPC call bypassing this form
 * entirely) still can't set its own price or user_id. This action only
 * forwards the form input and redirects on success.
 */
export async function createOrderAction(
  itemId: string,
  _prevState: CreateOrderState,
  formData: FormData
): Promise<CreateOrderState> {
  const depositorName = String(formData.get("depositor_name") ?? "").trim();

  if (!depositorName) {
    return { error: "입금자명을 입력해주세요." };
  }
  if (depositorName.length > 40) {
    return { error: "입금자명이 너무 깁니다." };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { error: "로그인이 필요합니다." };
  }

  // create_order() returns a single public.orders row (not SETOF), so
  // PostgREST hands it back as one JSON object already — no .single() here.
  const { data: order, error } = await supabase.rpc("create_order", {
    p_item_id: itemId,
    p_depositor_name: depositorName,
  });

  if (error || !order) {
    return { error: error?.message ?? "주문 생성에 실패했습니다." };
  }

  redirect(`/orders/${(order as { id: string }).id}`);
}
