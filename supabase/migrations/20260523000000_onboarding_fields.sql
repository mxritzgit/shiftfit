-- Onboarding-Felder: Aktivitätslevel (PAL) + Wunschgewicht.
-- onboarding_completed existiert bereits aus 20260516150000_create_profiles.sql
-- und gated jetzt das verpflichtende Onboarding in der App.

alter table public.profiles
  add column if not exists activity_level   text    not null default 'sedentary',
  add column if not exists target_weight_kg integer not null default 78;

-- Bestandszeilen: Wunschgewicht auf das aktuelle Gewicht setzen (neutral),
-- bis der User das Onboarding durchläuft und es bewusst wählt.
update public.profiles
  set target_weight_kg = weight_kg
  where target_weight_kg = 78 and weight_kg <> 78;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_activity_level_check'
  ) then
    alter table public.profiles add constraint profiles_activity_level_check
      check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'athlete'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_target_weight_range_check'
  ) then
    alter table public.profiles add constraint profiles_target_weight_range_check
      check (target_weight_kg between 30 and 300);
  end if;
end $$;
