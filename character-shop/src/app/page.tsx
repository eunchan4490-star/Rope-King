import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";

const PAY_STEPS = [
  {
    title: "구글 계정으로 로그인",
    desc: "이 사이트 우측 상단의 로그인 버튼을 눌러 구글 계정으로 로그인합니다. 게임 계정과 달라도 상관없어요.",
  },
  {
    title: "상점에서 원하는 상품 선택",
    desc: "🛒 루비 구매하러 가기 → 상품을 눌러 상세 화면으로 들어갑니다.",
  },
  {
    title: "입금자명 입력 후 구매 신청하기",
    desc: "실제로 입금하실 분 성함을 정확히 입력하고 '구매 신청하기'를 누릅니다.",
  },
  {
    title: "안내된 계좌로 정확한 금액 입금",
    desc: "신청 직후 화면에 은행/계좌번호/예금주가 표시됩니다. 계좌번호는 복사 버튼으로 바로 복사해서 은행 앱(토스, 카카오뱅크 등)에 붙여넣고, 표시된 금액과 똑같이 입금해주세요.",
  },
];

const REWARD_STEPS = [
  {
    title: "관리자가 입금 확인 후 승인",
    desc: "사람이 직접 입금 내역을 확인하기 때문에 시간이 조금 걸릴 수 있어요. 신청 화면을 나가도 괜찮습니다.",
  },
  {
    title: "주문내역에서 교환 코드 확인",
    desc: "승인되면 우측 상단 '주문내역'에서 해당 주문을 열어보세요. 'XXXX-XXXX-XXXX' 형태의 코드가 표시됩니다.",
  },
  {
    title: "게임 실행 → 설정 → 코드 입력",
    desc: "줄넘킹 게임을 켜고 타이틀 화면의 '설정' 버튼을 누른 뒤, '코드 입력' 칸에 코드를 붙여넣고 확인을 누릅니다.",
  },
  {
    title: "루비 즉시 지급 완료",
    desc: "확인을 누르는 즉시 루비가 게임에 지급돼요. 코드는 1회만 사용할 수 있으니 다른 사람에게 알려주지 마세요.",
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
          줄넘킹 루비 상점
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-white/70">
          앱스토어 결제 없이, 계좌이체로 간편하게 루비를 충전하는
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
          🛒 루비 구매하러 가기
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

      {/* How to pay */}
      <section className="rounded-2xl border border-white/10 bg-brand-panel/60 p-5">
        <p className="text-sm font-bold text-white">💳 어떻게 결제하나요?</p>
        <p className="mt-1 text-xs text-white/50">
          카드 결제가 아니라, 계좌이체로 직접 입금하는 방식이에요.
        </p>
        <ol className="mt-4 flex flex-col gap-4">
          {PAY_STEPS.map((step, index) => (
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

      {/* How to receive the reward */}
      <section className="rounded-2xl border border-white/10 bg-brand-panel/60 p-5">
        <p className="text-sm font-bold text-white">🎁 어떻게 보상을 받나요?</p>
        <p className="mt-1 text-xs text-white/50">
          입금이 확인되면 1회용 교환 코드가 발급되고, 그 코드를 게임에 직접 입력해서 받아요.
        </p>
        <ol className="mt-4 flex flex-col gap-4">
          {REWARD_STEPS.map((step, index) => (
            <li key={step.title} className="flex items-start gap-3">
              <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand-accent text-xs font-bold text-black">
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
