-- =============================================================================
-- 줄넘킹 캐릭터 상점 — Supabase schema
--
-- Run this whole file once in the Supabase SQL Editor (Dashboard → SQL Editor
-- → New query → paste → Run). Safe to re-run: every statement uses
-- IF NOT EXISTS / OR REPLACE / DROP POLICY IF EXISTS.
-- =============================================================================

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- profiles: one row per auth user, holds the admin/user role.
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

-- Auto-create a profile row whenever a new auth user signs up (Google login
-- included) so profiles.id always exists for every logged-in user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- -----------------------------------------------------------------------------
-- items: character catalog. Managed in the DB, not hardcoded in the app.
-- id is the game's own character id string (e.g. "skeleton") so the game
-- client can use it directly — see GAME_INTEGRATION.md.
-- -----------------------------------------------------------------------------
create table if not exists public.items (
  id text primary key,
  name text not null,
  price integer not null check (price >= 0),
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- item_type distinguishes one-time characters (grant via owned_items) from
-- repeatable currency top-ups (grant via a redeem_codes row instead — see
-- below). currency_amount is only meaningful when item_type = 'currency'.
alter table public.items
  add column if not exists item_type text not null default 'character'
    check (item_type in ('character', 'currency'));
alter table public.items
  add column if not exists currency_amount integer;

-- -----------------------------------------------------------------------------
-- orders: one purchase request per row.
-- -----------------------------------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  item_id text not null references public.items (id),
  price integer not null check (price >= 0),
  depositor_name text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  approved_at timestamptz
);

create index if not exists orders_user_id_idx on public.orders (user_id);
create index if not exists orders_status_idx on public.orders (status);

-- -----------------------------------------------------------------------------
-- owned_items: character ownership grants. One row per (user, item).
-- -----------------------------------------------------------------------------
create table if not exists public.owned_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  item_id text not null references public.items (id),
  acquired_at timestamptz not null default now(),
  source text not null default 'purchase',
  order_id uuid references public.orders (id),
  unique (user_id, item_id)
);

create index if not exists owned_items_user_id_idx on public.owned_items (user_id);

-- -----------------------------------------------------------------------------
-- redeem_codes: one row per currency-item purchase approval. code is what
-- the buyer types into the game's existing "코드 입력" field; redeemed
-- flips true the first (and only) time the game successfully claims it.
-- The game has no login system, so redemption happens anonymously — see
-- redeem_code() below for how that stays safe.
-- -----------------------------------------------------------------------------
create table if not exists public.redeem_codes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  code text not null unique,
  currency_amount integer not null check (currency_amount > 0),
  redeemed boolean not null default false,
  redeemed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists redeem_codes_user_id_idx on public.redeem_codes (user_id);
create index if not exists redeem_codes_order_id_idx on public.redeem_codes (order_id);

-- -----------------------------------------------------------------------------
-- is_admin(): SECURITY DEFINER so it can read profiles.role even though
-- profiles' own RLS policy (below) only lets a user read their own row.
-- Used both by other policies and by the approve/reject functions.
-- -----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- -----------------------------------------------------------------------------
-- Row Level Security
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.orders enable row level security;
alter table public.owned_items enable row level security;
alter table public.redeem_codes enable row level security;

-- profiles: a user can read their own profile; admins can read everyone's
-- (needed for the admin order list to show who placed each order). Nobody
-- (other than the trigger, which runs as SECURITY DEFINER and bypasses RLS)
-- can insert/update/delete their own role from the client.
drop policy if exists profiles_select_own_or_admin on public.profiles;
create policy profiles_select_own_or_admin on public.profiles
  for select
  using (id = auth.uid() or public.is_admin());

-- items: anyone signed in can browse active items. Only admins can manage
-- the catalog (do this from the Supabase Table Editor, not the app).
drop policy if exists items_select_active on public.items;
create policy items_select_active on public.items
  for select
  using (active = true or public.is_admin());

drop policy if exists items_admin_write on public.items;
create policy items_admin_write on public.items
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- orders: a user can only see their own orders; admins can see all.
-- Direct INSERT/UPDATE from the client is intentionally blocked entirely —
-- all writes must go through create_order()/approve_order()/reject_order(),
-- which re-validate everything server-side (see below).
drop policy if exists orders_select_own_or_admin on public.orders;
create policy orders_select_own_or_admin on public.orders
  for select
  using (user_id = auth.uid() or public.is_admin());

-- owned_items: a user can only see their own owned items; admins can see
-- all. No client-side INSERT/UPDATE/DELETE policy exists at all — the only
-- way a row appears here is through approve_order()'s SECURITY DEFINER
-- insert, which runs with elevated privileges regardless of RLS.
drop policy if exists owned_items_select_own_or_admin on public.owned_items;
create policy owned_items_select_own_or_admin on public.owned_items
  for select
  using (user_id = auth.uid() or public.is_admin());

-- redeem_codes: same shape as owned_items — own rows or admin, no direct
-- client writes (only approve_order()/redeem_code(), both SECURITY DEFINER).
drop policy if exists redeem_codes_select_own_or_admin on public.redeem_codes;
create policy redeem_codes_select_own_or_admin on public.redeem_codes
  for select
  using (user_id = auth.uid() or public.is_admin());

-- -----------------------------------------------------------------------------
-- create_order(): the only way an order can be created. Re-reads the price
-- from items server-side (never trusts a client-supplied price) and stamps
-- user_id from auth.uid() (never trusts a client-supplied user_id).
-- -----------------------------------------------------------------------------
create or replace function public.create_order(
  p_item_id text,
  p_depositor_name text
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item public.items%rowtype;
  v_order public.orders%rowtype;
  v_depositor_name text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  v_depositor_name := trim(coalesce(p_depositor_name, ''));
  if length(v_depositor_name) = 0 then
    raise exception 'depositor name is required';
  end if;
  if length(v_depositor_name) > 40 then
    raise exception 'depositor name is too long';
  end if;

  select * into v_item from public.items where id = p_item_id and active = true;
  if not found then
    raise exception 'item not found or not for sale';
  end if;

  insert into public.orders (user_id, item_id, price, depositor_name)
  values (auth.uid(), p_item_id, v_item.price, v_depositor_name)
  returning * into v_order;

  return v_order;
end;
$$;

revoke all on function public.create_order(text, text) from public;
grant execute on function public.create_order(text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- app_secrets: small key/value store for things like the Telegram bot token
-- that must never reach the frontend. RLS is enabled with NO policies at
-- all, so PostgREST (anon/authenticated) can never read or write this table
-- no matter what — only SECURITY DEFINER functions owned by the table owner
-- (which bypasses RLS) can read it, same as every other privileged read in
-- this schema. Actual secret values are inserted by hand in the SQL editor,
-- never committed here.
-- -----------------------------------------------------------------------------
create table if not exists public.app_secrets (
  key text primary key,
  value text not null
);
alter table public.app_secrets enable row level security;

-- -----------------------------------------------------------------------------
-- notify_new_order(): fires after every new order and pings a Telegram bot
-- so the admin doesn't have to keep checking /admin manually. Silently does
-- nothing if the bot token/chat id haven't been configured in app_secrets
-- yet — this must never block order creation. Uses pg_net (fire-and-forget,
-- async HTTP) so a slow/unreachable Telegram API can't fail the order.
-- -----------------------------------------------------------------------------
create extension if not exists pg_net;

create or replace function public.notify_new_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bot_token text;
  v_chat_id text;
  v_item_name text;
  v_text text;
begin
  select value into v_bot_token from public.app_secrets where key = 'telegram_bot_token';
  select value into v_chat_id from public.app_secrets where key = 'telegram_chat_id';
  if v_bot_token is null or v_chat_id is null then
    return new;
  end if;

  select name into v_item_name from public.items where id = new.item_id;

  v_text := format(
    E'\U0001F6D2 새 주문 접수!\n상품: %s\n금액: %s원\n입금자명: %s\n주문 ID: %s',
    coalesce(v_item_name, new.item_id),
    to_char(new.price, 'FM999,999,999'),
    new.depositor_name,
    new.id
  );

  -- Inline "승인"/"거절" buttons — tapping one hits the Telegram webhook
  -- (see character-shop/src/app/api/telegram-webhook/route.ts), which calls
  -- telegram_admin_action() below. callback_data just carries "action:id".
  -- timeout_milliseconds bumped from pg_net's 5000ms default: a real order
  -- (2026-09-01) was silently lost to a slow TLS handshake to
  -- api.telegram.org that took ~5s on its own, one order this can't fix
  -- retroactively but should make far less likely going forward.
  perform net.http_post(
    url := format('https://api.telegram.org/bot%s/sendMessage', v_bot_token),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'chat_id', v_chat_id,
      'text', v_text,
      'reply_markup', jsonb_build_object(
        'inline_keyboard', jsonb_build_array(
          jsonb_build_array(
            jsonb_build_object('text', '✅ 승인', 'callback_data', 'approve:' || new.id::text),
            jsonb_build_object('text', '❌ 거절', 'callback_data', 'reject:' || new.id::text)
          )
        )
      )
    ),
    timeout_milliseconds := 15000
  );

  return new;
end;
$$;

drop trigger if exists on_order_created_notify on public.orders;
create trigger on_order_created_notify
  after insert on public.orders
  for each row
  execute function public.notify_new_order();

-- -----------------------------------------------------------------------------
-- approve_order(): the only way an order can move to 'approved' and grant
-- ownership. Runs as one transaction (a single PL/pgSQL function call is
-- already atomic), re-checks is_admin() itself, and is idempotent — calling
-- it again on an already-approved order is a harmless no-op, and the
-- unique(user_id, item_id) constraint on owned_items plus ON CONFLICT DO
-- NOTHING is a second layer against ever double-granting.
-- -----------------------------------------------------------------------------
-- _approve_order_core() holds the actual approval logic with NO auth check
-- of its own — it trusts its caller entirely. Only two callers exist:
-- approve_order() (authenticated + is_admin() check) and
-- telegram_admin_action() (secret-token check, for the Telegram approve
-- button). Both are SECURITY DEFINER owned by the same role, so calling
-- this internal function needs no separate grant. Never grant execute on
-- this function to anyone directly.
create or replace function public._approve_order_core(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_item public.items%rowtype;
  v_code text;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'order not found';
  end if;

  if v_order.status = 'approved' then
    return v_order; -- already approved: idempotent no-op, not an error
  end if;
  if v_order.status = 'rejected' then
    raise exception 'cannot approve a rejected order';
  end if;

  select * into v_item from public.items where id = v_order.item_id;

  update public.orders
    set status = 'approved', approved_at = now()
    where id = p_order_id
    returning * into v_order;

  if v_item.item_type = 'currency' then
    -- Character items grant via owned_items (below); currency items mint a
    -- one-time redeem code instead, since owned_items' unique(user_id,
    -- item_id) would block buying the same top-up twice. Format: 3 groups
    -- of 4 uppercase alphanumeric chars — easy to type by hand. The
    -- collision-retry loop is a formality (the codespace is huge) but
    -- costs nothing to keep.
    loop
      v_code := upper(
        substr(md5(random()::text || clock_timestamp()::text), 1, 4) || '-' ||
        substr(md5(random()::text || clock_timestamp()::text), 1, 4) || '-' ||
        substr(md5(random()::text || clock_timestamp()::text), 1, 4)
      );
      exit when not exists (select 1 from public.redeem_codes where code = v_code);
    end loop;

    insert into public.redeem_codes (order_id, user_id, code, currency_amount)
    values (p_order_id, v_order.user_id, v_code, v_item.currency_amount);
  else
    insert into public.owned_items (user_id, item_id, source, order_id)
    values (v_order.user_id, v_order.item_id, 'purchase', p_order_id)
    on conflict (user_id, item_id) do nothing;
  end if;

  return v_order;
end;
$$;

revoke all on function public._approve_order_core(uuid) from public;

create or replace function public.approve_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return public._approve_order_core(p_order_id);
end;
$$;

revoke all on function public.approve_order(uuid) from public;
grant execute on function public.approve_order(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- redeem_code(): called by the GAME CLIENT, not the website. No login
-- exists in the game, so this is intentionally callable by the anon role —
-- security rests on the code itself being an unguessable random token (12
-- alphanumeric chars, astronomically large codespace) plus single-use
-- (redeemed flag flipped atomically in the same UPDATE that checks it, so
-- two simultaneous redeem attempts with the same code can't both succeed).
-- -----------------------------------------------------------------------------
create or replace function public.redeem_code(p_code text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount integer;
begin
  update public.redeem_codes
    set redeemed = true, redeemed_at = now()
    where code = upper(trim(coalesce(p_code, ''))) and redeemed = false
    returning currency_amount into v_amount;

  if v_amount is null then
    raise exception 'invalid or already used code';
  end if;

  return v_amount;
end;
$$;

revoke all on function public.redeem_code(text) from public;
grant execute on function public.redeem_code(text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- reject_order(): only affects orders still pending, so an approved order
-- can never be silently flipped to rejected after the fact.
-- -----------------------------------------------------------------------------
-- _reject_order_core(): same "no auth check, trusts its caller" split as
-- _approve_order_core() — only reject_order() and telegram_admin_action()
-- may call it.
create or replace function public._reject_order_core(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  update public.orders
    set status = 'rejected'
    where id = p_order_id and status = 'pending'
    returning * into v_order;

  if not found then
    raise exception 'order not found or not pending';
  end if;

  return v_order;
end;
$$;

revoke all on function public._reject_order_core(uuid) from public;

create or replace function public.reject_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return public._reject_order_core(p_order_id);
end;
$$;

revoke all on function public.reject_order(uuid) from public;
grant execute on function public.reject_order(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- telegram_admin_action(): lets the Telegram bot's "승인"/"거절" inline
-- buttons approve/reject an order without the admin ever opening the
-- website. This is NOT gated by auth.uid()/is_admin() — there is no
-- Supabase session in a Telegram webhook request — so instead it's gated by
-- a shared secret stored in app_secrets (never readable via PostgREST,
-- see app_secrets above) that only the Next.js webhook route also knows.
-- The route itself independently verifies the request came from Telegram
-- via the X-Telegram-Bot-Api-Secret-Token header before ever calling this,
-- so this is a second, defense-in-depth check, not the only one.
-- -----------------------------------------------------------------------------
create or replace function public.telegram_admin_action(
  p_order_id uuid,
  p_action text,
  p_secret text
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expected_secret text;
begin
  select value into v_expected_secret from public.app_secrets where key = 'telegram_webhook_secret';
  if v_expected_secret is null or p_secret is null or p_secret <> v_expected_secret then
    raise exception 'not authorized';
  end if;

  if p_action = 'approve' then
    return public._approve_order_core(p_order_id);
  elsif p_action = 'reject' then
    return public._reject_order_core(p_order_id);
  else
    raise exception 'unknown action';
  end if;
end;
$$;

revoke all on function public.telegram_admin_action(uuid, text, text) from public;
grant execute on function public.telegram_admin_action(uuid, text, text) to anon;

-- -----------------------------------------------------------------------------
-- telegram_list_inquiries(): lets the Telegram bot show recent inquiries on
-- request (the "/문의" command in the webhook route), so the admin can
-- browse past submissions without opening Supabase. Same secret-gated
-- pattern as telegram_admin_action() — no auth.uid() available here.
-- -----------------------------------------------------------------------------
create or replace function public.telegram_list_inquiries(p_secret text, p_limit integer default 5)
returns setof public.inquiries
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expected_secret text;
begin
  select value into v_expected_secret from public.app_secrets where key = 'telegram_webhook_secret';
  if v_expected_secret is null or p_secret is null or p_secret <> v_expected_secret then
    raise exception 'not authorized';
  end if;

  return query
    select * from public.inquiries
    order by created_at desc
    limit greatest(1, least(coalesce(p_limit, 5), 20));
end;
$$;

revoke all on function public.telegram_list_inquiries(text, integer) from public;
grant execute on function public.telegram_list_inquiries(text, integer) to anon;

-- -----------------------------------------------------------------------------
-- get_my_owned_items(): convenience RPC for the game client — returns just
-- the array of item_id strings the caller owns. Equivalent to querying
-- owned_items directly (RLS already restricts that to your own rows), this
-- just saves the game client a bit of parsing. See GAME_INTEGRATION.md.
-- -----------------------------------------------------------------------------
create or replace function public.get_my_owned_items()
returns text[]
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(array_agg(item_id order by acquired_at), array[]::text[])
  from public.owned_items
  where user_id = auth.uid();
$$;

revoke all on function public.get_my_owned_items() from public;
grant execute on function public.get_my_owned_items() to authenticated;

-- -----------------------------------------------------------------------------
-- Seed data: 3 example characters (kept inactive — see GAME_INTEGRATION.md
-- section 4 for how their id matches assets/characters/<id>/ 1:1) plus the
-- live currency top-up item. Safe to re-run (upsert on id).
-- -----------------------------------------------------------------------------
insert into public.items (id, name, price, image_url, active, item_type, currency_amount)
values
  ('skele', '스켈레', 4900, null, false, 'character', null),
  ('witch', '마녀', 3900, null, false, 'character', null),
  ('scientist', '과학자', 3900, null, false, 'character', null),
  ('gem_100', '루비 20개', 1000, 'https://rope-king.vercel.app/ruby.png', true, 'currency', 20)
on conflict (id) do update set
  name = excluded.name,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  item_type = excluded.item_type,
  currency_amount = excluded.currency_amount;

-- -----------------------------------------------------------------------------
-- inquiries: the "문의하기" (contact us) form. Anyone can submit — logged in
-- or not — so this does NOT require auth.uid(); user_id is just recorded
-- when available for reference. Only admins can read submissions back
-- through PostgREST (RLS below); the actual notification (Telegram +
-- optional email) happens in notify_new_inquiry(), same pattern as orders.
-- -----------------------------------------------------------------------------
create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  contact_email text,
  message text not null,
  created_at timestamptz not null default now(),
  handled boolean not null default false
);
alter table public.inquiries enable row level security;
drop policy if exists inquiries_select_admin on public.inquiries;
create policy inquiries_select_admin on public.inquiries
  for select using (public.is_admin());

-- submit_inquiry(): the only way a row can land in inquiries. Re-validates
-- the message server-side (never trusts a client to have already done so)
-- and stamps user_id from auth.uid() when a session exists, same
-- never-trust-the-client posture as create_order().
create or replace function public.submit_inquiry(p_message text, p_contact_email text)
returns public.inquiries
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.inquiries%rowtype;
  v_message text;
  v_contact text;
begin
  v_message := trim(coalesce(p_message, ''));
  if length(v_message) = 0 then
    raise exception 'message is required';
  end if;
  if length(v_message) > 2000 then
    raise exception 'message is too long';
  end if;

  v_contact := nullif(trim(coalesce(p_contact_email, '')), '');

  insert into public.inquiries (user_id, contact_email, message)
  values (auth.uid(), v_contact, v_message)
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.submit_inquiry(text, text) from public;
grant execute on function public.submit_inquiry(text, text) to anon, authenticated;

-- notify_new_inquiry(): pings the same Telegram bot used for orders (works
-- immediately, nothing extra to configure) and, if an app_secrets row
-- 'resend_api_key' has been set, also emails it via Resend's API using
-- their no-signup-required onboarding@resend.dev sender — to whatever
-- 'notify_email' is set to in app_secrets. Both are best-effort: a failure
-- in either must never block the inquiry itself from being saved (the row
-- in the table is the actual source of truth an admin can always check).
create or replace function public.notify_new_inquiry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bot_token text;
  v_chat_id text;
  v_resend_key text;
  v_notify_email text;
  v_text text;
begin
  v_text := format(
    E'\U0001F4E9 새 문의가 접수됐어요!\n%s\n\n답장 받을 이메일: %s\n문의 ID: %s',
    new.message,
    coalesce(new.contact_email, '(입력 안 함)'),
    new.id
  );

  select value into v_bot_token from public.app_secrets where key = 'telegram_bot_token';
  select value into v_chat_id from public.app_secrets where key = 'telegram_chat_id';
  if v_bot_token is not null and v_chat_id is not null then
    perform net.http_post(
      url := format('https://api.telegram.org/bot%s/sendMessage', v_bot_token),
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := jsonb_build_object('chat_id', v_chat_id, 'text', v_text),
      timeout_milliseconds := 15000
    );
  end if;

  select value into v_resend_key from public.app_secrets where key = 'resend_api_key';
  select value into v_notify_email from public.app_secrets where key = 'notify_email';
  if v_resend_key is not null and v_notify_email is not null then
    perform net.http_post(
      url := 'https://api.resend.com/emails',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_resend_key
      ),
      body := jsonb_build_object(
        'from', '줄넘킹 문의 <onboarding@resend.dev>',
        'to', jsonb_build_array(v_notify_email),
        'subject', '[줄넘킹] 새 문의가 접수됐어요',
        'text', v_text
      ),
      timeout_milliseconds := 15000
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_inquiry_created_notify on public.inquiries;
create trigger on_inquiry_created_notify
  after insert on public.inquiries
  for each row
  execute function public.notify_new_inquiry();

-- -----------------------------------------------------------------------------
-- Making a user admin: run this manually after they've logged in at least
-- once (so their profiles row exists), replacing the email below.
--
--   update public.profiles set role = 'admin' where email = 'you@example.com';
--
-- -----------------------------------------------------------------------------
