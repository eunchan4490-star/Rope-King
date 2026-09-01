"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function NavBar({
  email,
  isAdmin,
}: {
  email: string | null;
  isAdmin: boolean;
}) {
  const router = useRouter();

  async function handleLogout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-10 border-b border-white/10 bg-brand-bg/95 backdrop-blur">
      <nav className="mx-auto flex max-w-lg flex-wrap items-center justify-between gap-y-2 px-4 py-3 text-sm">
        <Link href="/" className="font-bold text-brand-gold">
          캐릭터 상점
        </Link>
        <div className="flex flex-wrap items-center gap-3">
          <Link href="/shop" className="hover:text-brand-gold">
            상점
          </Link>
          {email && (
            <Link href="/orders" className="hover:text-brand-gold">
              주문내역
            </Link>
          )}
          <Link href="/contact" className="hover:text-brand-gold">
            문의
          </Link>
          {isAdmin && (
            <Link href="/admin" className="hover:text-brand-gold">
              관리자
            </Link>
          )}
          {email ? (
            <>
              <span
                title={email}
                className="max-w-[110px] truncate text-xs text-white/50"
              >
                {email}
              </span>
              <button
                onClick={handleLogout}
                className="shrink-0 rounded bg-white/10 px-2 py-1 text-xs hover:bg-white/20"
              >
                로그아웃
              </button>
            </>
          ) : (
            <Link
              href="/login"
              className="rounded bg-brand-gold px-2 py-1 text-xs font-semibold text-black"
            >
              로그인
            </Link>
          )}
        </div>
      </nav>
    </header>
  );
}
