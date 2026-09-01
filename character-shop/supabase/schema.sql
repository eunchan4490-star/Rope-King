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
-- approve_order(): the only way an order can move to 'approved' and grant
-- ownership. Runs as one transaction (a single PL/pgSQL function call is
-- already atomic), re-checks is_admin() itself, and is idempotent — calling
-- it again on an already-approved order is a harmless no-op, and the
-- unique(user_id, item_id) constraint on owned_items plus ON CONFLICT DO
-- NOTHING is a second layer against ever double-granting.
-- -----------------------------------------------------------------------------
create or replace function public.approve_order(p_order_id uuid)
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
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

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
create or replace function public.reject_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

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

revoke all on function public.reject_order(uuid) from public;
grant execute on function public.reject_order(uuid) to authenticated;

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
  ('gem_100', '100루피', 1000, null, true, 'currency', 100)
on conflict (id) do update set
  name = excluded.name,
  price = excluded.price,
  active = excluded.active,
  item_type = excluded.item_type,
  currency_amount = excluded.currency_amount;

-- -----------------------------------------------------------------------------
-- Making a user admin: run this manually after they've logged in at least
-- once (so their profiles row exists), replacing the email below.
--
--   update public.profiles set role = 'admin' where email = 'you@example.com';
--
-- -----------------------------------------------------------------------------
