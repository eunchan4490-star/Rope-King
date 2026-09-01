import { cookies } from "next/headers";
import { createServerClient, type CookieOptions } from "@supabase/ssr";

/**
 * Supabase client for Server Components, Server Actions, and Route
 * Handlers. Runs with the signed-in user's own session (read from cookies),
 * so every query still goes through Postgres RLS as that user — this is
 * NOT a service-role/admin client. See supabase/schema.sql for the
 * SECURITY DEFINER functions (create_order, approve_order, reject_order)
 * that safely escalate specific, narrow operations after re-checking
 * auth.uid() / is_admin() themselves.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch {
            // Called from a Server Component render — middleware.ts is
            // responsible for refreshing the session cookie in that case.
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: "", ...options });
          } catch {
            // Same as above.
          }
        },
      },
    }
  );
}
