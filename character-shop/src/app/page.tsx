import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";

const STEPS = [
  {
    title: "구글 계정으로 로그인",
    desc: "게임에서 쓰는 것과 같은 구글 계정이면 됩니다.",
  },
  {
    title: "상점에서 루피 구매 신청",
    desc: "원하는 만큼 신청하고 입금자명을 입력해주세요.",
  },
  {
    title: "안내된 계좌로 입금",
    desc: "신청 화면에 계좌번호가 바로 표시됩니다.",
  },
  {
    title: "입금 확인 후 코드 발급",
    desc: "확인되면 주문 페이지에 교환 코드가 자동으로 뜹니다.",
  },
  {
    title: "게임에서 코드 입력",
    desc: "설정 화면의 코드 입력 칸에 넣으면 루피가 바로 지급돼요.",
  },
];

export default async function HomePage() {
  const user = await getCurrentUser();

  return (
    <div className="flex flex-col gap-8">
      {/* Hero */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-panel via-brand-panel to-black/40 p-6 text-center shadow-lg shadow-black/30">
        <div className="text-4xl">💎</div>
        <h1 className="mt-2 text-2xl font-extrabold tracking-tight text-brand-gold">
          줄넘킹 루피 상점
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-white/70">
          앱스토어 결제 없이, 계좌이체로 간편하게 루피를 충전하는
          <br />
          줄넘킹 공식 외부 상점입니다.
        </p>
      </section>

      {/* CTA buttons */}
      <div className="grid grid-cols-1 gap-3">
        <Link
          href="/shop"
          className="rounded-xl bg-brand-gold px-4 py-4 text-center text-base font-bold text-black shadow-md shadow-brand-gold/20 transition hover:brightness-110"
        >
          🛒 루피 구매하러 가기
        </Link>
        {user ? (
          <Link
            href="/orders"
            className="rounded-xl bg-white/10 px-4 py-3 text-center font-semibold transition hover:bg-white/20"
          >
            📄 내 주문 내역 보기
          </Link>
        ) : (
          <Link
            href="/login"
            className="rounded-xl bg-white/10 px-4 py-3 text-center font-semibold transition hover:bg-white/20"
          >
            👤 로그인하기
          </Link>
        )}
      </div>

      {/* How it works */}
      <section className="rounded-2xl border border-white/10 bg-brand-panel/60 p-5">
        <p className="text-sm font-bold text-white">
          🧭 이렇게 이용하세요
        </p>
        <ol className="mt-4 flex flex-col gap-4">
          {STEPS.map((step, index) => (
            <li key={step.title} className="flex items-start gap-3">
              <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand-gold text-xs font-bold text-black">
                {index + 1}
              </span>
              <div>
                <p className="text-sm font-semibold text-white">{step.title}</p>
                <p className="text-xs leading-relaxed text-white/60">{step.desc}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      {/* Reassurance / FAQ-ish notes */}
      <section className="flex flex-col gap-3 rounded-2xl border border-white/10 p-5 text-xs leading-relaxed text-white/60">
        <p className="text-sm font-bold text-white">💬 알아두면 좋은 점</p>
        <div className="flex items-start gap-2">
          <span>⏱️</span>
          <p>
            입금 확인은 사람이 직접 하기 때문에, 신청 후 코드가 나오기까지
            시간이 걸릴 수 있어요. 조금만 기다려주세요.
          </p>
        </div>
        <div className="flex items-start gap-2">
          <span>✍️</span>
          <p>
            입금자명을 실제로 입금하실 분 성함과 똑같이 입력해주시면 확인이
            훨씬 빨라집니다.
          </p>
        </div>
        <div className="flex items-start gap-2">
          <span>🔑</span>
          <p>
            교환 코드는 <b className="text-white/80">1회만</b> 사용할 수
            있어요. 게임 안 <b className="text-white/80">설정 → 코드 입력</b>{" "}
            칸에 정확히 입력해주세요.
          </p>
        </div>
      </section>
    </div>
  );
}
