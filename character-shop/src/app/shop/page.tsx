import Link from "next/link";
import Image from "next/image";
import { createClient } from "@/lib/supabase/server";
import type { Item } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function ShopPage() {
  const supabase = await createClient();
  const { data: items, error } = await supabase
    .from("items")
    .select("id, name, price, image_url, active, created_at")
    .eq("active", true)
    .order("price", { ascending: true });

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-bold text-brand-gold">캐릭터 상점</h1>

      {error && (
        <p className="text-sm text-brand-danger">
          상품 목록을 불러오지 못했습니다: {error.message}
        </p>
      )}

      {!error && (!items || items.length === 0) && (
        <p className="text-sm text-white/60">현재 판매 중인 캐릭터가 없습니다.</p>
      )}

      <div className="grid grid-cols-2 gap-3">
        {(items as Item[] | null)?.map((item) => (
          <Link
            key={item.id}
            href={`/shop/${item.id}`}
            className="flex flex-col items-center gap-2 rounded-lg bg-brand-panel p-3 text-center hover:bg-white/10"
          >
            <div className="relative h-20 w-20 overflow-hidden rounded bg-black/30">
              {item.image_url ? (
                <Image
                  src={item.image_url}
                  alt={item.name}
                  fill
                  sizes="80px"
                  className="object-contain"
                  unoptimized
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-xs text-white/40">
                  이미지 없음
                </div>
              )}
            </div>
            <span className="text-sm font-semibold">{item.name}</span>
            <span className="text-xs text-brand-gold">
              {item.price.toLocaleString()}원
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
