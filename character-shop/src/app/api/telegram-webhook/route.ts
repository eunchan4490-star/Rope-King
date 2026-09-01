import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

/**
 * Telegram calls this when the admin taps 승인/거절 on a new-order
 * notification (see supabase/schema.sql notify_new_order()). There is no
 * Supabase session here — Telegram, not a logged-in browser, is the
 * caller — so authorization works differently from every other write in
 * this app:
 *
 * 1. Telegram itself is verified via the X-Telegram-Bot-Api-Secret-Token
 *    header, which must match the secret_token registered with setWebhook.
 * 2. The actual approve/reject is done by telegram_admin_action(), a
 *    SECURITY DEFINER function gated by a second copy of the same secret
 *    stored in app_secrets (never readable via PostgREST) — not by
 *    auth.uid()/is_admin(), which don't apply here.
 *
 * This route uses the plain anon-key client (no cookies) since it never
 * acts as a signed-in user.
 */
export async function POST(req: NextRequest) {
  const secretHeader = req.headers.get("x-telegram-bot-api-secret-token");
  if (
    !process.env.TELEGRAM_WEBHOOK_SECRET ||
    secretHeader !== process.env.TELEGRAM_WEBHOOK_SECRET
  ) {
    return new NextResponse("forbidden", { status: 403 });
  }

  const update = await req.json();
  const callback = update.callback_query;
  if (!callback || typeof callback.data !== "string") {
    return NextResponse.json({ ok: true });
  }

  const [action, orderId] = callback.data.split(":");
  const botToken = process.env.TELEGRAM_BOT_TOKEN;

  let resultText: string;
  if (
    (action !== "approve" && action !== "reject") ||
    !orderId ||
    !botToken
  ) {
    resultText = "알 수 없는 요청이에요.";
  } else {
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
    const { error } = await supabase.rpc("telegram_admin_action", {
      p_order_id: orderId,
      p_action: action,
      p_secret: process.env.TELEGRAM_WEBHOOK_SECRET,
    });

    if (error) {
      resultText = `실패: ${error.message}`;
    } else {
      resultText = action === "approve" ? "✅ 승인 완료" : "❌ 거절 완료";
    }
  }

  if (botToken) {
    await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        callback_query_id: callback.id,
        text: resultText,
      }),
    });

    if (callback.message) {
      // Replace the buttons with a plain result label so the admin can't
      // double-tap the same order later.
      await fetch(
        `https://api.telegram.org/bot${botToken}/editMessageReplyMarkup`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: callback.message.chat.id,
            message_id: callback.message.message_id,
            reply_markup: {
              inline_keyboard: [[{ text: resultText, callback_data: "noop" }]],
            },
          }),
        }
      );
    }
  }

  return NextResponse.json({ ok: true });
}
