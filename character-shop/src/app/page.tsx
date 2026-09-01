import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";

export default async function HomePage() {
  const user = await getCurrentUser();

  return (
    <div className="flex flex-col gap-6">
      <section className="rounded-xl bg-brand-panel p-6 text-center">
        <h1 className="text-2xl font-bold text-brand-gold">줄넘킹 캐릭터 상점</h1>
        <p className="mt-2 text-sm text-white/70">
          게임 앱 밖에서만 이용할 수 있는 캐릭터 구매 신청 페이지입니다.
          <br />
          입금 확인 후 관리자가 직접 캐릭터를 지급합니다.
        </p>
      </section>

      <div className="grid grid-cols-1 gap-3">
        <Link
          href="/shop"
          className="rounded-lg bg-brand-gold px-4 py-3 text-center font-semibold text-black"
        >
          상점 보러가기
        </Link>
        {user ? (
          <Link
            href="/orders"
            className="rounded-lg bg-white/10 px-4 py-3 text-center font-semibold"
          >
            내 주문 내역
          </Link>
        ) : (
          <Link
            href="/login"
            className="rounded-lg bg-white/10 px-4 py-3 text-center font-semibold"
          >
            로그인
          </Link>
        )}
      </div>

      <section className="rounded-lg border border-white/10 p-4 text-xs leading-relaxed text-white/60">
        <p className="font-semibold text-white/80">이용 안내</p>
        <ol className="mt-1 list-decimal space-y-1 pl-4">
          <li>구글 계정으로 로그인합니다.</li>
          <li>상점에서 원하는 캐릭터의 구매 신청을 누릅니다.</li>
          <li>안내된 계좌로 입금 후 입금자명을 입력합니다.</li>
          <li>관리자가 입금을 확인하면 캐릭터가 자동으로 지급됩니다.</li>
          <li>게임에 같은 계정으로 로그인하면 구매한 캐릭터를 사용할 수 있습니다.</li>
        </ol>
      </section>
    </div>
  );
}
