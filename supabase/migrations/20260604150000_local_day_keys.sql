-- DATA-6: Kanonischer lokaler Tages-Schluessel fuer Mahlzeiten + Koffein.
--
-- Problem: Mahlzeiten wurden client-seitig per isSameDay(.toLocal()) einem Tag
-- zugeordnet, Koffein dagegen serverseitig ueber ein UTC-Halboffenes Fenster
-- aus der *naiven* lokalen Mitternacht (gte/lt auf consumed_at). Ueber eine
-- DST-Umstellung oder einen Zonenwechsel hinweg koennen diese beiden Sichten
-- auseinanderlaufen: ein Eintrag um 23:45 Ortszeit landet dann fuer Koffein und
-- fuer Mahlzeiten in unterschiedlichen „Tagen".
--
-- Loesung: eine explizite Spalte `local_day date`, die der Client aus der
-- LOKALEN Wanduhr des Eintrags fuellt (YYYY-MM-DD, identisches Format zu
-- daily_logs.log_date / sleep_entries.sleep_date). Ab dieser Migration filtert
-- der Caffeine-Sync auf `local_day` (eq) statt auf das UTC-Fenster, und das
-- Meals-Bucketing bevorzugt `local_day` gegenueber isSameDay.
--
-- Diese Migration ist ADDITIV + IDEMPOTENT:
--   * add column if not exists -> mehrfaches Anwenden ist gefahrlos.
--   * Die Spalte ist NULLABLE (kein NOT NULL): bestehende Zeilen bleiben gueltig,
--     der Client faellt fuer NULL-Zeilen auf die alte Logik zurueck.
--   * RLS/Grants bleiben unveraendert: neue Spalten erben automatisch die
--     bestehenden Table-Policies und die table-level CRUD-Grants fuer
--     authenticated (Spalten-Adds brauchen keinen separaten GRANT; ein GRANT
--     auf Tabellen-Ebene deckt alle Spalten ab). Siehe 20260516180000_grants.sql.

-- ---------------------------------------------------------------------------
-- 1) Spalten anlegen (additiv, idempotent)
-- ---------------------------------------------------------------------------
alter table public.logged_meals
  add column if not exists local_day date;

alter table public.caffeine_entries
  add column if not exists local_day date;

-- ---------------------------------------------------------------------------
-- 2) Backfill bestehender Zeilen (einmalige Approximation)
--
-- Referenz: die Server-Daten wurden bisher ueberwiegend mit der Zeitzone
-- 'Europe/Berlin' erfasst (FitPilot ist eine deutschsprachige App; bestehende
-- Accounts liegen in DE). Ohne pro-Zeile gespeicherten Original-Offset ist der
-- exakte lokale Tag historischer Zeilen nicht rekonstruierbar — wir nehmen
-- daher die dokumentierte Referenzzone und leiten local_day aus dem
-- gespeicherten UTC-Timestamp ab:
--
--     local_day := (timestamptz AT TIME ZONE 'Europe/Berlin')::date
--
-- 'AT TIME ZONE <zone>' rechnet den timestamptz in die Wanduhr dieser Zone um
-- (inkl. korrektem historischem DST-Offset aus der IANA-tz-Datenbank), und der
-- ::date-Cast nimmt davon den Kalendertag — genau das, was localDayKey(.toLocal())
-- auf einem DE-Geraet liefert. Fuer die seltenen Eintraege, die in einer anderen
-- Zone erfasst wurden, ist dies eine bewusste Naeherung; ab jetzt schreibt der
-- Client den exakten lokalen Tag mit, sodass kuenftige Zeilen praezise sind.
--
-- Nur Zeilen mit local_day IS NULL anfassen -> idempotent (ein erneuter Lauf
-- ueberschreibt bereits gefuellte/korrekte Werte nicht).
-- ---------------------------------------------------------------------------
update public.logged_meals
  set local_day = (logged_at at time zone 'Europe/Berlin')::date
  where local_day is null;

update public.caffeine_entries
  set local_day = (consumed_at at time zone 'Europe/Berlin')::date
  where local_day is null;

-- ---------------------------------------------------------------------------
-- 3) Indizes fuer die neuen Filter (eq auf user_id + local_day)
--    caffeine: loadCaffeineDay/resetCaffeineDay filtern jetzt (user_id, local_day).
--    meals: loadLoggedMeals laedt weiterhin alles pro user_id, aber ein
--    zusammengesetzter Index haelt kuenftige local_day-Filter guenstig.
-- ---------------------------------------------------------------------------
create index if not exists caffeine_entries_user_local_day_idx
  on public.caffeine_entries (user_id, local_day);

create index if not exists logged_meals_user_local_day_idx
  on public.logged_meals (user_id, local_day);
