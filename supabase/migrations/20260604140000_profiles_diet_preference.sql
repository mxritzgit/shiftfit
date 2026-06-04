-- profiles.diet_preference: Ernährungspräferenz des Users (none/vegetarian/
-- vegan/pescetarian). Steuert, welche Rezepte FitPilot aktiv empfiehlt
-- (Empfehlungs-Carousel + „Passt zu deinem Ziel") — keine medizinische
-- Allergie-Garantie, der User kann über den Kategorie-Filter weiterhin alles
-- durchsuchen. Wird von ProfileSync gelesen UND geschrieben
-- (lib/src/services/profile_sync.dart). Default 'none' (empfiehlt alles), damit
-- Bestandszeilen unverändert bleiben.
--
-- Additiv/idempotent (add column if not exists / guarded constraint): bricht
-- eine bereits out-of-band gepatchte Live-DB nicht. GRANTs für authenticated
-- laufen über die default privileges aus 20260516180000_grants.sql (die Spalte
-- gehört zur bestehenden Tabelle, kein neuer Table-Grant nötig). RLS auf
-- public.profiles besteht bereits (User-Daten, row owner = id).

alter table public.profiles
  add column if not exists diet_preference text not null default 'none';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_diet_preference_check'
  ) then
    alter table public.profiles add constraint profiles_diet_preference_check
      check (diet_preference in ('none', 'vegetarian', 'vegan', 'pescetarian'));
  end if;
end $$;
