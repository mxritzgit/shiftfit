-- FitPilot — atomare Lifetime-Stats- & Streak-RPCs (Audit 2026-06-04).
--
-- Bisher liest der Client lifetime_stats, addiert clientseitig und schreibt die
-- Summe zurueck (read-modify-write). Bei parallelen Geraeten/Tabs geht so ein
-- Increment verloren (last-write-wins ueberschreibt). Diese beiden RPCs machen
-- das Hochzaehlen serverseitig atomar (UPDATE col = col + p_x), sodass kein
-- Increment mehr verloren geht. Die Streak-Logik (record_workout_day) liest
-- last_workout_date PERSISTIERT aus der DB statt aus dem fluechtigen
-- In-Memory-State — ueberlebt App-Neustart und Geraetewechsel.
--
-- Rein additiv & idempotent (create or replace function / on conflict upsert).
-- Aufsetzpunkt: 20260516160000_app_data_schema.sql (lifetime_stats mit
-- workouts_completed, meals_logged, water_total_ml, steps_recorded, weight_logs)
-- + 20260530090000_streak_and_weekly_plan.sql (current_streak, longest_streak,
-- last_workout_date). Grant-/search_path-Stil gespiegelt von
-- 20260517220000_security_hardening.sql + 20260602120100_regrant_chat_session_rpcs.sql.
--
-- WICHTIG: Beide RPCs sind security definer + user-scoped (auth.uid()), daher
-- sicher an authenticated zu granten. Sie legen die lifetime_stats-Zeile per
-- upsert an, falls sie fehlt (Erst-User vor Bootstrap-Trigger), damit ein
-- Increment nie auf 0 Zeilen laeuft.
--
-- HINWEIS: Das Client-Wiring (lib/src/services/lifetime_stats_sync.dart +
-- daily_log_sync.dart) erfolgt in der Integrations-Welle, NICHT hier. Status der
-- Migration selbst: am 2026-06-07 gegen die Live-DB verifiziert — angewendet UND
-- in supabase_migrations.schema_migrations registriert (beide RPCs vorhanden).

-- ---------------------------------------------------------------------------
-- 1) increment_lifetime_stats — atomares Hochzaehlen der Kumulativ-Zaehler.
--    Jeder Parameter default 0, sodass der Caller nur die relevanten Felder
--    setzt. WHERE user_id = auth.uid() => nur die eigene Zeile.
-- ---------------------------------------------------------------------------
create or replace function public.increment_lifetime_stats(
  p_water       integer default 0,
  p_steps       integer default 0,
  p_meals       integer default 0,
  p_weight_logs integer default 0,
  p_workouts    integer default 0
)
returns public.lifetime_stats
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.lifetime_stats;
begin
  if v_uid is null then
    raise exception 'EX_USER_REQUIRED' using errcode = '22023';
  end if;

  -- Zeile sicherstellen (Erst-User vor Bootstrap-Trigger), dann atomar
  -- hochzaehlen. on conflict do update mit demselben col = col + p_x, damit
  -- der erste Aufruf eines neuen Users nicht auf 0 Zeilen laeuft.
  insert into public.lifetime_stats as ls (
    user_id,
    water_total_ml,
    steps_recorded,
    meals_logged,
    weight_logs,
    workouts_completed
  ) values (
    v_uid,
    greatest(p_water, 0),
    greatest(p_steps, 0),
    greatest(p_meals, 0),
    greatest(p_weight_logs, 0),
    greatest(p_workouts, 0)
  )
  on conflict (user_id) do update set
    water_total_ml     = ls.water_total_ml     + greatest(p_water, 0),
    steps_recorded     = ls.steps_recorded     + greatest(p_steps, 0),
    meals_logged       = ls.meals_logged       + greatest(p_meals, 0),
    weight_logs        = ls.weight_logs        + greatest(p_weight_logs, 0),
    workouts_completed = ls.workouts_completed + greatest(p_workouts, 0)
  returning ls.* into v_row;

  return v_row;
end;
$$;

revoke execute on function public.increment_lifetime_stats(integer, integer, integer, integer, integer)
  from public, anon;
grant execute on function public.increment_lifetime_stats(integer, integer, integer, integer, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 2) record_workout_day — persistente Streak-Fortschreibung fuer EINEN Tag.
--    Liest last_workout_date aus der DB (nicht aus In-Memory-State):
--      * p_day == last_workout_date      -> idempotent, keine Streak-Aenderung
--                                           (auch workouts_completed bleibt gleich)
--      * p_day == last_workout_date + 1  -> current_streak + 1
--      * sonst (Luecke / NULL / Zukunft) -> current_streak = 1
--    longest_streak = greatest(longest_streak, current_streak),
--    last_workout_date = p_day, workouts_completed + 1 (ausser im idempotenten Fall).
-- ---------------------------------------------------------------------------
create or replace function public.record_workout_day(p_day date)
returns public.lifetime_stats
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_row  public.lifetime_stats;
  v_last date;
  v_new_streak integer;
begin
  if v_uid is null then
    raise exception 'EX_USER_REQUIRED' using errcode = '22023';
  end if;
  if p_day is null then
    raise exception 'EX_DAY_REQUIRED' using errcode = '22023';
  end if;

  -- Zeile sicherstellen, falls der User noch keine lifetime_stats hat. Beim
  -- frischen Insert ist last_workout_date NULL -> der erste Workout-Tag startet
  -- die Streak bei 1 (else-Zweig unten).
  insert into public.lifetime_stats (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  select last_workout_date into v_last
  from public.lifetime_stats
  where user_id = v_uid
  for update;

  -- Idempotenz: gleicher Tag schon gezaehlt -> Zeile unveraendert zurueckgeben.
  if v_last is not null and v_last = p_day then
    select * into v_row from public.lifetime_stats where user_id = v_uid;
    return v_row;
  end if;

  if v_last is not null and p_day = v_last + 1 then
    v_new_streak := null;  -- Signal: bestehende Streak + 1 (unten aufgeloest)
  else
    v_new_streak := 1;     -- Luecke, erster Tag, NULL oder Zukunfts-/Rueckdatum
  end if;

  update public.lifetime_stats as ls set
    current_streak = case
      when v_new_streak is null then ls.current_streak + 1
      else 1
    end,
    longest_streak = greatest(
      ls.longest_streak,
      case when v_new_streak is null then ls.current_streak + 1 else 1 end
    ),
    last_workout_date  = p_day,
    workouts_completed = ls.workouts_completed + 1
  where ls.user_id = v_uid
  returning ls.* into v_row;

  return v_row;
end;
$$;

revoke execute on function public.record_workout_day(date) from public, anon;
grant execute on function public.record_workout_day(date) to authenticated;
