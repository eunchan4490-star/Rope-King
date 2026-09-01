import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import type { Item } from "@/lib/types";
import PurchaseForm from "./PurchaseForm";

export const dynamic = "force-dynamic";

export default async function ItemPurchasePage({
  params,
}: {
  params: Promise<{ itemId: string }>;
}) {
  const { itemId } = await params;
  const supabase = await createClient();
  const { data: item } = await supabase
    .from("items")
    .select("id, name, price, image_url, active, item_type, currency_amount, created_at")
    .eq("id", itemId)
    .eq("active", true)
    .single<Item>();

  if (!item) {
    notFound();
  }

  const user = await getCurrentUser();
  const isCurrency = item.item_type === "currency";

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col items-center gap-2 rounded-2xl bg-brand-panel p-6 shadow-sm shadow-black/20">
        <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-full bg-black/30">
          {item.image_url ? (
            <Image
              src={item.image_url}
              alt={item.name}
              fill
              sizes="96px"
              className="object-contain"
              unoptimized
            />
          ) : (
            <span className="text-4xl">{isCurrency ? "💎" : "🧑"}</span>
          )}
        </div>
        <h1 className="text-lg font-bold">{item.name}</h1>
        {isCurrency && item.currency_amount && (
          <p className="text-xs text-brand-accent">루피 {item.currency_amount}개 지급</p>
        )}
        <p className="text-xl font-extrabold text-brand-gold">
          {item.price.toLocaleString()}원
        </p>
      </div>

      {user ? (
        <>
          <div className="flex flex-col gap-1 rounded-lg border-2 border-brand-danger bg-brand-danger/15 p-3 text-center">
            <p className="text-sm font-extrabold text-brand-danger">
              ⏰ 지급까지 최대 5시간 걸릴 수 있어요
            </p>
            <p className="text-sm font-extrabold text-brand-danger">
              🌙 자정~오전 8시는 지급 불가능해요
            </p>
          </div>
          <p className="text-center text-xs text-white/50">
            입금자명을 입력하고 신청하면, 다음 화면에서 입금할 계좌를
            안내해드려요.
          </p>
          <PurchaseForm itemId={item.id} />
        </>
      ) : (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-white/10 p-5 text-sm text-white/70">
          <p>구매 신청은 로그인 후 이용할 수 있습니다.</p>
          <Link
            href="/login"
            className="rounded-lg bg-brand-gold px-4 py-2 font-semibold text-black"
          >
            로그인하러 가기
          </Link>
        </div>
      )}
    </div>
  );
}
