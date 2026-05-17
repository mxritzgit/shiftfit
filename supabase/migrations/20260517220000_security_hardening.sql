-- FitPilot security hardening: endpoint rate limits, tighter grants,
-- and defensive DB constraints for all app-facing tables.

-- Required for hashing rate-limit subjects without storing raw identifiers.
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1) Least-privilege defaults and explicit anon lockdown
-- ---------------------------------------------------------------------------
revoke all on schema public from public;
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke all on all functions in schema public from anon;

-- Mobile clients still need schema usage for PostgREST, but row access is
-- controlled by table privileges + RLS policies below.
grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
-- Do not blanket-expose public RPC/functions to mobile clients. Grant
-- authenticated EXECUTE only on explicitly reviewed RPCs as they are added.
revoke execute on all functions in schema public from authenticated;

grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;

alter default privileges in schema public
  revoke all on tables from anon;
alter default privileges in schema public
  revoke all on sequences from anon;
alter default privileges in schema public
  revoke all on functions from anon;
alter default privileges in schema public
  revoke execute on functions from authenticated;

-- ---------------------------------------------------------------------------
-- 2) Durable Edge Function rate-limit bucket
-- ---------------------------------------------------------------------------
create table if not exists public.edge_rate_limits (
  scope text not null,
  subject_hash text not null,
  window_start timestamptz not null,
  window_seconds integer not null check (window_seconds between 1 and 86400),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (scope, subject_hash, window_start, window_seconds)
);

alter table public.edge_rate_limits enable row level security;

-- No anon/authenticated grants: only security-definer RPC + service_role may
-- touch buckets. This keeps user IDs/IPs out of client-readable tables.
revoke all on public.edge_rate_limits from anon, authenticated;
grant all on public.edge_rate_limits to service_role;

create or replace function public.consume_edge_rate_limit(
  p_scope text,
  p_subject text,
  p_limit integer,
  p_window_seconds integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  v_window_start timestamptz;
  v_subject_hash text;
  v_count integer;
  v_reset_at timestamptz;
begin
  if p_scope is null or length(trim(p_scope)) = 0 or length(p_scope) > 80 then
    raise exception 'invalid rate limit scope';
  end if;
  if p_subject is null or length(trim(p_subject)) = 0 or length(p_subject) > 512 then
    raise exception 'invalid rate limit subject';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 10000 then
    raise exception 'invalid rate limit limit';
  end if;
  if p_window_seconds is null or p_window_seconds < 1 or p_window_seconds > 86400 then
    raise exception 'invalid rate limit window';
  end if;

  v_window_start := to_timestamp(
    floor(extract(epoch from v_now) / p_window_seconds) * p_window_seconds
  );
  v_reset_at := v_window_start + make_interval(secs => p_window_seconds);
  v_subject_hash := encode(digest(p_subject, 'sha256'), 'hex');

  insert into public.edge_rate_limits (
    scope, subject_hash, window_start, window_seconds, request_count, updated_at
  ) values (
    p_scope, v_subject_hash, v_window_start, p_window_seconds, 1, v_now
  )
  on conflict (scope, subject_hash, window_start, window_seconds)
  do update set
    request_count = public.edge_rate_limits.request_count + 1,
    updated_at = excluded.updated_at
  returning request_count into v_count;

  return jsonb_build_object(
    'allowed', v_count <= p_limit,
    'limit', p_limit,
    'remaining', greatest(p_limit - v_count, 0),
    'resetAt', v_reset_at,
    'windowSeconds', p_window_seconds
  );
end;
$$;

revoke all on function public.consume_edge_rate_limit(text, text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_edge_rate_limit(text, text, integer, integer)
  to service_role;

-- Keep the bucket table small without relying on a scheduler. Called by the
-- function opportunistically via service_role if desired.
create or replace function public.prune_edge_rate_limits()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted integer;
begin
  delete from public.edge_rate_limits
  where window_start < now() - interval '2 days';
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function public.prune_edge_rate_limits() from public, anon, authenticated;
grant execute on function public.prune_edge_rate_limits() to service_role;

-- ---------------------------------------------------------------------------
-- 3) Defensive constraints for app data integrity / mass-assignment blast radius
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'profiles_display_name_length_check') then
    alter table public.profiles add constraint profiles_display_name_length_check
      check (char_length(display_name) <= 80);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'profiles_avatar_url_length_check') then
    alter table public.profiles add constraint profiles_avatar_url_length_check
      check (avatar_url is null or char_length(avatar_url) <= 2048);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'profiles_biometrics_range_check') then
    alter table public.profiles add constraint profiles_biometrics_range_check
      check (
        weight_kg between 30 and 300 and
        height_cm between 100 and 250 and
        age_years between 13 and 100
      );
  end if;
  if not exists (select 1 from pg_constraint where conname = 'profiles_goals_range_check') then
    alter table public.profiles add constraint profiles_goals_range_check
      check (
        daily_steps_goal between 1000 and 100000 and
        daily_kcal_goal between 800 and 7000 and
        daily_water_goal_ml between 500 and 12000 and
        daily_sleep_goal_minutes between 180 and 900 and
        protein_goal_g between 0 and 400 and
        carbs_goal_g between 0 and 800 and
        fat_goal_g between 0 and 300
      );
  end if;

  if not exists (select 1 from pg_constraint where conname = 'daily_logs_safe_ranges_check') then
    alter table public.daily_logs add constraint daily_logs_safe_ranges_check
      check (
        water_ml between 0 and 12000 and
        steps between 0 and 100000 and
        char_length(mood_note) <= 500 and
        cardinality(completed_block_ids) <= 100 and
        cardinality(completed_habit_ids) <= 100
      );
  end if;

  if not exists (select 1 from pg_constraint where conname = 'logged_meals_safe_ranges_check') then
    alter table public.logged_meals add constraint logged_meals_safe_ranges_check
      check (
        char_length(meal_name) between 1 and 160 and
        calories_kcal between 0 and 10000 and
        estimated_g between 0 and 10000 and
        (protein_g is null or protein_g between 0 and 1000) and
        (carbs_g is null or carbs_g between 0 and 1000) and
        (fat_g is null or fat_g between 0 and 1000) and
        (barcode is null or char_length(barcode) <= 64) and
        (brand is null or char_length(brand) <= 120) and
        (source_label is null or char_length(source_label) <= 80) and
        octet_length(payload::text) <= 200000
      );
  end if;

  if not exists (select 1 from pg_constraint where conname = 'favorite_meals_safe_ranges_check') then
    alter table public.favorite_meals add constraint favorite_meals_safe_ranges_check
      check (
        char_length(favorite_key) between 1 and 180 and
        char_length(meal_name) between 1 and 160 and
        calories_kcal between 0 and 10000 and
        estimated_g between 0 and 10000 and
        (barcode is null or char_length(barcode) <= 64) and
        (brand is null or char_length(brand) <= 120) and
        (source_label is null or char_length(source_label) <= 80) and
        octet_length(payload::text) <= 200000
      );
  end if;

  if not exists (select 1 from pg_constraint where conname = 'weight_log_safe_range_check') then
    alter table public.weight_log add constraint weight_log_safe_range_check
      check (weight_kg between 20 and 400);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'caffeine_entries_safe_range_check') then
    alter table public.caffeine_entries add constraint caffeine_entries_safe_range_check
      check (mg between 1 and 1000);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'lifetime_stats_nonnegative_check') then
    alter table public.lifetime_stats add constraint lifetime_stats_nonnegative_check
      check (
        workouts_completed >= 0 and
        meals_logged >= 0 and
        water_total_ml >= 0 and
        steps_recorded >= 0 and
        weight_logs >= 0
      );
  end if;
end $$;
