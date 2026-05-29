-- FitPilot — Streak-Durability + persistenter Wochenplan
--
-- Rein additiv & idempotent (add column if not exists / create table if
-- not exists / drop policy if exists vor create). Aufsetzpunkt:
-- 20260516160000_app_data_schema.sql (legt daily_logs + lifetime_stats an,
-- set_updated_at() stammt aus 20260516150000_create_profiles.sql).
--
-- Behoben wird: workoutStreak/lifetimeStats waren rein in-memory und
-- resetteten bei jedem App-Neustart; der Wochenplan war ebenfalls
-- fluechtig. Diese Migration gibt allen dreien eine echte Heimat.
--
-- WICHTIG (42501): Diese Migration wird per raw SQL ueber die Supabase-
-- Management-API angewendet, NICHT ueber den Dashboard-Tabelleneditor.
-- Dabei werden Tabellen-GRANTs fuer die authenticated-Rolle NICHT
-- automatisch gesetzt (Postgres prueft Privileges VOR RLS). Die neue
-- Tabelle weekly_plans braucht daher explizite Grants — unten gesetzt,
-- analog zu 20260516180000_grants.sql.

-- ---------------------------------------------------------------------------
-- 1) daily_logs — robustes Workout-Signal
--    completed_block_ids wird bei Voll-Abschluss vom Client geleert, taugt
--    also nicht als History. workout_completed bleibt true fuer den Tag.
-- ---------------------------------------------------------------------------
alter table public.daily_logs
  add column if not exists workout_completed boolean not null default false;

-- ---------------------------------------------------------------------------
-- 2) lifetime_stats — Streak-Felder (1:1 Dart LifetimeStats)
-- ---------------------------------------------------------------------------
alter table public.lifetime_stats
  add column if not exists current_streak    integer not null default 0,
  add column if not exists longest_streak    integer not null default 0,
  add column if not exists last_workout_date date;

-- ---------------------------------------------------------------------------
-- 3) weekly_plans — ein 7-Tage-Plan pro User (Index 0=Mo .. 6=So)
-- ---------------------------------------------------------------------------
create table if not exists public.weekly_plans (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  days        text[] not null default '{}',
  updated_at  timestamptz not null default now()
);

drop trigger if exists weekly_plans_set_updated_at on public.weekly_plans;
create trigger weekly_plans_set_updated_at
  before update on public.weekly_plans
  for each row execute function public.set_updated_at();

alter table public.weekly_plans enable row level security;

drop policy if exists "weekly_plans_select_own"  on public.weekly_plans;
drop policy if exists "weekly_plans_insert_own"  on public.weekly_plans;
drop policy if exists "weekly_plans_update_own"  on public.weekly_plans;
drop policy if exists "weekly_plans_delete_own"  on public.weekly_plans;

create policy "weekly_plans_select_own"
  on public.weekly_plans for select to authenticated
  using (user_id = auth.uid());
create policy "weekly_plans_insert_own"
  on public.weekly_plans for insert to authenticated
  with check (user_id = auth.uid());
create policy "weekly_plans_update_own"
  on public.weekly_plans for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "weekly_plans_delete_own"
  on public.weekly_plans for delete to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4) GRANTs — bei raw-SQL-Apply NICHT automatisch. Ohne diese kriegt der
--    eingeloggte User trotz RLS-Policy ein 42501 auf weekly_plans.
--    daily_logs/lifetime_stats hatten ihre Grants schon (alte Migration),
--    aber wir ziehen sie idempotent nach — grant ist re-runnable.
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.weekly_plans to authenticated;
grant all                            on public.weekly_plans to service_role;
grant select, insert, update, delete on public.daily_logs     to authenticated;
grant select, insert, update, delete on public.lifetime_stats to authenticated;

-- Default Privileges sind in 20260516180000_grants.sql bereits fuer das
-- public-Schema gesetzt; neue Tabellen vom postgres-Owner erben die Grants
-- normalerweise. Die expliziten Grants oben sind das Sicherheitsnetz fuer
-- den raw-Management-API-Pfad.
