import Link from "next/link";
import Image from "next/image";
import { createClient } from "@/lib/supabase/server";
import type { Item } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function ShopPage() {
  const supabase = await createClient();
  const { data: items, error } = await supabase
    .from("items")
    .select("id, name, price, image_url, active, item_type, currency_amount, created_at")
    .eq("active", true)
    .order("price", { ascending: true });

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-xl font-bold text-brand-gold">상점</h1>
        <p className="mt-1 text-xs text-white/50">
          원하는 상품을 눌러 구매를 신청해주세요.
        </p>
      </div>

      {error && (
        <p className="text-sm text-brand-danger">
          상품 목록을 불러오지 못했습니다: {error.message}
        </p>
      )}

      {!error && (!items || items.length === 0) && (
        <p className="text-sm text-white/60">현재 판매 중인 상품이 없습니다.</p>
      )}

      <div className="grid grid-cols-2 gap-3">
        {(items as Item[] | null)?.map((item) => (
          <Link
            key={item.id}
            href={`/shop/${item.id}`}
            className="flex flex-col items-center gap-2 rounded-xl bg-brand-panel p-4 text-center shadow-sm shadow-black/20 transition hover:bg-white/10"
          >
            <div className="relative flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-black/30">
              {item.image_url ? (
                <Image
                  src={item.image_url}
                  alt={item.name}
                  fill
                  sizes="80px"
                  className="object-contain"
                  unoptimized
                />
              ) : item.item_type === "currency" ? (
                <span className="text-3xl">💎</span>
              ) : (
                <span className="text-3xl">🧑</span>
              )}
            </div>
            <span className="text-sm font-semibold">{item.name}</span>
            {item.item_type === "currency" && item.currency_amount && (
              <span className="rounded-full bg-brand-accent/15 px-2 py-0.5 text-[10px] font-semibold text-brand-accent">
                루비 {item.currency_amount}개
              </span>
            )}
            <span className="text-xs font-bold text-brand-gold">
              {item.price.toLocaleString()}원
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
