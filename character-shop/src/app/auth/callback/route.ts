import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Handles the redirect back from Supabase/Google OAuth: exchanges the
// one-time `code` for a session and stores it in cookies via the server
// Supabase client, then sends the user on to the shop.
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/shop";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(
    `${origin}/login?error=${encodeURIComponent("로그인에 실패했습니다. 다시 시도해주세요.")}`
  );
}
