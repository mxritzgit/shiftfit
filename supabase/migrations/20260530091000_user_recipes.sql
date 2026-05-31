-- FitPilot — user_recipes (selbst angelegte Rezepte)
--
-- Rein additiv. Speichert vom User selbst erstellte Rezepte (Name, Portion,
-- Makros, Zutaten) pro user_id. RLS strikt user_id = auth.uid(), GRANTs fuer
-- die authenticated-Rolle EXPLIZIT (Raw-SQL via Management-API/psql setzt sie
-- NICHT automatisch — siehe 20260516180000_grants.sql).
--
-- Hinweis: rein additive Migration. Das zugehoerige Dart-Client-Wiring
-- (user_recipes_sync + FitPilotSync-Registrierung) ist bewusst noch nicht
-- vorhanden — das Feature ist daher in der App aktuell noch nicht aktiv.

-- ---------------------------------------------------------------------------
-- 1) Tabelle
-- ---------------------------------------------------------------------------
create table if not exists public.user_recipes (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  slug           text not null,
  title          text not null,
  description    text not null default '',
  portion        text not null default '',
  ingredients    text not null default '',
  preparation    text not null default '',
  image_asset    text not null default '',
  calories_kcal  integer not null default 0 check (calories_kcal >= 0),
  protein_g      integer not null default 0 check (protein_g >= 0),
  carbs_g        integer not null default 0 check (carbs_g >= 0),
  fat_g          integer not null default 0 check (fat_g >= 0),
  estimated_g    integer not null default 0 check (estimated_g >= 0),
  categories     text[] not null default '{}',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (user_id, slug)
);

create index if not exists user_recipes_user_created_at_idx
  on public.user_recipes (user_id, created_at desc);

-- updated_at-Trigger (Funktion existiert seit 20260516150000_create_profiles.sql)
drop trigger if exists user_recipes_set_updated_at on public.user_recipes;
create trigger user_recipes_set_updated_at
  before update on public.user_recipes
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 2) Row Level Security — user sieht/aendert nur eigene Zeilen
-- ---------------------------------------------------------------------------
alter table public.user_recipes enable row level security;

drop policy if exists "user_recipes_select_own"  on public.user_recipes;
drop policy if exists "user_recipes_insert_own"  on public.user_recipes;
drop policy if exists "user_recipes_update_own"  on public.user_recipes;
drop policy if exists "user_recipes_delete_own"  on public.user_recipes;

create policy "user_recipes_select_own"
  on public.user_recipes for select to authenticated
  using (user_id = auth.uid());
create policy "user_recipes_insert_own"
  on public.user_recipes for insert to authenticated
  with check (user_id = auth.uid());
create policy "user_recipes_update_own"
  on public.user_recipes for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_recipes_delete_own"
  on public.user_recipes for delete to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 3) GRANTs — explizit, da raw SQL sie nicht automatisch vergibt.
--    service_role bekommt vollen Zugriff (Server/Backfill).
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.user_recipes to authenticated;
grant all on public.user_recipes to service_role;
