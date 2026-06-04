-- FitPilot — workout_sets (echtes Workout-Logging, PROD-5)
--
-- Rein additiv + idempotent. Speichert einzelne geloggte Arbeitssaetze
-- (Uebung, Gewicht, Wiederholungen, optional RPE) pro user_id. Laeuft
-- additiv NEBEN dem bestehenden statischen Template-Advisor (ShiftMeta) —
-- nichts Bestehendes wird angefasst.
--
-- RLS strikt user_id = auth.uid(). GRANTs fuer die authenticated-Rolle
-- EXPLIZIT, da Raw-SQL via Management-API/psql sie NICHT automatisch setzt
-- (siehe 20260516180000_grants.sql; sonst 42501 "permission denied").
--
-- Hinweis: Das Client-Wiring (WorkoutLogSync ist in FitPilotSync registriert)
-- existiert; die Verdrahtung der UI in die HomePage (Boot-Load + Injektion
-- der optionalen WeekPlannerScreen-Parameter) erfolgt durch den Integrator.

-- ---------------------------------------------------------------------------
-- 1) Tabelle
-- ---------------------------------------------------------------------------
create table if not exists public.workout_sets (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  exercise    text not null,
  weight_kg   numeric(6,2) not null default 0 check (weight_kg >= 0),
  reps        integer not null default 0 check (reps >= 0),
  rpe         integer check (rpe is null or (rpe >= 1 and rpe <= 10)),
  logged_at   timestamptz not null default now(),
  local_day   date not null default (now() at time zone 'utc')::date,
  created_at  timestamptz not null default now()
);

-- Schneller Zugriff auf "die Saetze eines Users an einem lokalen Tag" und
-- generell auf die juengste Historie pro User.
create index if not exists workout_sets_user_local_day_idx
  on public.workout_sets (user_id, local_day desc);

create index if not exists workout_sets_user_exercise_logged_idx
  on public.workout_sets (user_id, exercise, logged_at desc);

-- ---------------------------------------------------------------------------
-- 2) Row Level Security — user sieht/aendert nur eigene Zeilen
-- ---------------------------------------------------------------------------
alter table public.workout_sets enable row level security;

drop policy if exists "workout_sets_select_own" on public.workout_sets;
drop policy if exists "workout_sets_insert_own" on public.workout_sets;
drop policy if exists "workout_sets_update_own" on public.workout_sets;
drop policy if exists "workout_sets_delete_own" on public.workout_sets;

create policy "workout_sets_select_own"
  on public.workout_sets for select to authenticated
  using (user_id = auth.uid());
create policy "workout_sets_insert_own"
  on public.workout_sets for insert to authenticated
  with check (user_id = auth.uid());
create policy "workout_sets_update_own"
  on public.workout_sets for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "workout_sets_delete_own"
  on public.workout_sets for delete to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 3) GRANTs — explizit, da raw SQL sie nicht automatisch vergibt.
--    service_role bekommt vollen Zugriff (Server/Backfill).
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.workout_sets to authenticated;
grant all on public.workout_sets to service_role;
