-- Coach-Chat Schema
--
-- chat_messages       : Konversation pro User (role = user|assistant|system).
-- chat_quota_usage    : Zaehler pro User pro Tag (UTC) - das Rate-Limit.
-- claim_chat_quota()  : atomare RPC fuer die Edge Function, gibt remaining
--                       zurueck oder wirft EX_QUOTA_EXCEEDED. Damit kann
--                       der Client das Limit nicht clientseitig umgehen.

-- ---------------------------------------------------------------------------
-- chat_messages
-- ---------------------------------------------------------------------------
create table if not exists public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  role        text not null check (role in ('user', 'assistant', 'system')),
  content     text not null,
  refusal     boolean not null default false,
  refusal_reason text,
  created_at  timestamptz not null default now()
);

create index if not exists chat_messages_user_created_idx
  on public.chat_messages (user_id, created_at);

alter table public.chat_messages enable row level security;

drop policy if exists "chat_messages_select_own" on public.chat_messages;
create policy "chat_messages_select_own"
  on public.chat_messages
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Schreiben passiert ausschliesslich aus der Edge Function (service_role) -
-- der Client soll keine Messages direkt einfuegen koennen (sonst kann er die
-- Konversationshistorie faelschen). Deshalb keine INSERT/UPDATE/DELETE
-- Policies fuer authenticated.

-- ---------------------------------------------------------------------------
-- chat_quota_usage
-- ---------------------------------------------------------------------------
create table if not exists public.chat_quota_usage (
  user_id    uuid not null references auth.users(id) on delete cascade,
  day        date not null,
  used_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

alter table public.chat_quota_usage enable row level security;

drop policy if exists "chat_quota_select_own" on public.chat_quota_usage;
create policy "chat_quota_select_own"
  on public.chat_quota_usage
  for select
  to authenticated
  using (auth.uid() = user_id);

-- INSERT/UPDATE wieder nur service_role.

-- ---------------------------------------------------------------------------
-- claim_chat_quota: atomare Reservierung eines Slots
--
--   - Default-Limit 5/Tag (Parameter p_daily_limit).
--   - Returns: { used integer, remaining integer }.
--   - Wirft Exception 'EX_QUOTA_EXCEEDED' wenn der User das Limit erreicht.
--   - SECURITY DEFINER, damit auch service_role-Aufrufe konsistent gegen
--     auth.uid() laufen koennen.
-- ---------------------------------------------------------------------------
create or replace function public.claim_chat_quota(
  p_user_id      uuid,
  p_daily_limit  integer default 5
) returns table (used integer, remaining integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'utc')::date;
  v_used  integer;
begin
  if p_user_id is null then
    raise exception 'EX_USER_REQUIRED' using errcode = '22023';
  end if;

  insert into public.chat_quota_usage (user_id, day, used_count, updated_at)
    values (p_user_id, v_today, 0, now())
    on conflict (user_id, day) do nothing;

  -- Reihe sperren um Race-Conditions bei parallelen Requests zu vermeiden.
  select used_count into v_used
    from public.chat_quota_usage
    where user_id = p_user_id and day = v_today
    for update;

  if v_used >= p_daily_limit then
    raise exception 'EX_QUOTA_EXCEEDED' using errcode = 'P0001';
  end if;

  update public.chat_quota_usage
     set used_count = used_count + 1,
         updated_at = now()
   where user_id = p_user_id and day = v_today;

  used      := v_used + 1;
  remaining := p_daily_limit - used;
  return next;
end;
$$;

-- Nur service_role darf claim_chat_quota aufrufen - der Client geht ueber
-- die Edge Function, die den Service-Role-Key benutzt. Damit ist sicher,
-- dass der User-Client das Limit nicht client-seitig erhoeht.
revoke all on function public.claim_chat_quota(uuid, integer) from public;
revoke all on function public.claim_chat_quota(uuid, integer) from authenticated;
grant execute on function public.claim_chat_quota(uuid, integer) to service_role;

-- ---------------------------------------------------------------------------
-- get_chat_quota_today: read-only, fuer das Frontend (Counter im UI).
-- ---------------------------------------------------------------------------
create or replace function public.get_chat_quota_today(
  p_daily_limit integer default 5
) returns table (used integer, remaining integer, daily_limit integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'utc')::date;
  v_used  integer;
  v_uid   uuid := auth.uid();
begin
  if v_uid is null then
    used        := 0;
    remaining   := p_daily_limit;
    daily_limit := p_daily_limit;
    return next;
    return;
  end if;

  select used_count into v_used
    from public.chat_quota_usage
    where user_id = v_uid and day = v_today;

  v_used      := coalesce(v_used, 0);
  used        := v_used;
  remaining   := greatest(p_daily_limit - v_used, 0);
  daily_limit := p_daily_limit;
  return next;
end;
$$;

grant execute on function public.get_chat_quota_today(integer)
  to authenticated, service_role;
