"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleGoogleLogin() {
    setLoading(true);
    setError(null);
    const supabase = createClient();
    const siteUrl =
      process.env.NEXT_PUBLIC_SITE_URL || window.location.origin;
    const { error: signInError } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${siteUrl}/auth/callback`,
      },
    });
    if (signInError) {
      setError(signInError.message);
      setLoading(false);
    }
    // On success the browser is redirected to Google, then back to
    // /auth/callback — nothing else to do here.
  }

  return (
    <div className="flex flex-col items-center gap-6 py-10 text-center">
      <h1 className="text-xl font-bold text-brand-gold">로그인</h1>
      <p className="text-sm text-white/70">
        게임과 동일한 계정으로 로그인합니다.
        <br />
        구매한 캐릭터는 같은 계정으로 게임에서 사용할 수 있습니다.
      </p>
      <button
        onClick={handleGoogleLogin}
        disabled={loading}
        className="w-full max-w-xs rounded-lg bg-white px-4 py-3 font-semibold text-black disabled:opacity-60"
      >
        {loading ? "이동 중..." : "Google로 로그인"}
      </button>
      {error && <p className="text-sm text-brand-danger">{error}</p>}
    </div>
  );
}
