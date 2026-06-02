-- profiles.weight_goal: das pro-Tempo gewählte Abnehm-/Zunehm-/Halte-Ziel.
-- Wird von ProfileSync gelesen UND geschrieben (lib/src/services/profile_sync.dart:22,77),
-- fehlte aber bislang in den Repo-Migrationen. Eine frische DB hätte damit keinen
-- weight_goal-Spalt -> jeder Profil-Save (upsert().select().single()) würde eine
-- PostgrestException werfen und onboarding_completed nie persistieren (Onboarding-Loop).
-- Idempotent (add column if not exists / guarded constraint): bricht eine bereits
-- out-of-band gepatchte Live-DB nicht.

alter table public.profiles
  add column if not exists weight_goal text not null default 'maintain';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_weight_goal_check'
  ) then
    alter table public.profiles add constraint profiles_weight_goal_check
      check (weight_goal in (
        'lose1kg', 'lose075kg', 'lose05kg', 'lose025kg',
        'maintain', 'gain025kg', 'gain05kg'
      ));
  end if;
end $$;
