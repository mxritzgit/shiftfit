-- ---------------------------------------------------------------------------
-- favorite_meals.pinned — kuratierbare Favoriten (PROD-4)
--
-- Trennt die zwei Sorten Eintraege in favorite_meals:
--   * pinned = true  -> vom User explizit angeheftete Favoriten (Herz).
--                       Bleiben dauerhaft, werden NICHT gekappt.
--   * pinned = false -> Auto-Recents (zuletzt geloggte Mahlzeiten). Der Client
--                       kappt diese auf die letzten N; nur sie sind fluechtig.
--
-- Default false: bestehende Zeilen bleiben Auto-Recents, das alte Verhalten
-- (take(5)) gilt also unveraendert weiter, bis der User explizit anheftet.
-- ---------------------------------------------------------------------------
alter table public.favorite_meals
  add column if not exists pinned boolean not null default false;
