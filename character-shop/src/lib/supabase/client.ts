import { createBrowserClient } from "@supabase/ssr";

/**
 * Supabase client for Client Components (browser). Only ever uses the
 * public anon key — the RLS policies + SECURITY DEFINER RPC functions in
 * supabase/schema.sql are what actually enforce access control, not this
 * key's secrecy.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
