"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type AdminActionState = {
  error: string | null;
};

/**
 * Both actions below call SECURITY DEFINER Postgres functions
 * (approve_order / reject_order in supabase/schema.sql) that re-check
 * is_admin() themselves using the caller's own auth.uid() — so even if
 * this page's admin check were somehow bypassed, or these actions were
 * invoked directly, a non-admin session still can't approve or reject
 * anything. approve_order also does the status flip + owned_items insert
 * as a single transaction and is safe to call twice (already-approved
 * orders are a no-op, not a duplicate grant).
 */
export async function approveOrderAction(
  orderId: string
): Promise<AdminActionState> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("approve_order", {
    p_order_id: orderId,
  });
  if (error) {
    return { error: error.message };
  }
  revalidatePath("/admin");
  return { error: null };
}

export async function rejectOrderAction(
  orderId: string
): Promise<AdminActionState> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("reject_order", {
    p_order_id: orderId,
  });
  if (error) {
    return { error: error.message };
  }
  revalidatePath("/admin");
  return { error: null };
}
