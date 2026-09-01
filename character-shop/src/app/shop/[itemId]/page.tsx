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
    .select("id, name, price, image_url, active, created_at")
    .eq("id", itemId)
    .eq("active", true)
    .single<Item>();

  if (!item) {
    notFound();
  }

  const user = await getCurrentUser();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col items-center gap-2 rounded-lg bg-brand-panel p-4">
        <div className="relative h-28 w-28 overflow-hidden rounded bg-black/30">
          {item.image_url ? (
            <Image
              src={item.image_url}
              alt={item.name}
              fill
              sizes="112px"
              className="object-contain"
              unoptimized
            />
          ) : null}
        </div>
        <h1 className="text-lg font-bold">{item.name}</h1>
        <p className="text-brand-gold">{item.price.toLocaleString()}원</p>
      </div>

      {user ? (
        <PurchaseForm itemId={item.id} />
      ) : (
        <div className="flex flex-col items-center gap-2 rounded-lg border border-white/10 p-4 text-sm text-white/70">
          <p>구매 신청은 로그인 후 이용할 수 있습니다.</p>
          <Link
            href="/login"
            className="rounded bg-brand-gold px-4 py-2 font-semibold text-black"
          >
            로그인하러 가기
          </Link>
        </div>
      )}
    </div>
  );
}
