import { createClient } from "@/lib/supabase/server";

export type CurrentUser = {
  id: string;
  email: string | null;
  isAdmin: boolean;
};

/**
 * Server-only helper: resolves the signed-in user (from the session cookie)
 * and their admin status by reading profiles.role. This is the one place
 * "am I an admin" gets decided for page-level redirects — but it is not the
 * real security boundary. The real boundary is Postgres RLS plus the
 * is_admin()/approve_order()/reject_order() functions in
 * supabase/schema.sql, which re-check role themselves no matter what any
 * page does.
 */
export async function getCurrentUser(): Promise<CurrentUser | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  return {
    id: user.id,
    email: user.email ?? null,
    isAdmin: profile?.role === "admin",
  };
}
