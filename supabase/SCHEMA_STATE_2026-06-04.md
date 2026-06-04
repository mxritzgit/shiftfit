# Supabase Schema-State — Stand 2026-06-04

Dieses Dokument haelt fest, **welche Repo-Migrationen NOCH NICHT auf die Live-DB
angewendet** sind und welche noch gegen die Live-DB verifiziert werden muessen.
Es ist reine Dokumentation + Grundlage fuer den CI-Drift-Gate
(`supabase-migration-drift` in `.github/workflows/security.yml`). Diese Datei
beruehrt die Live-DB **nicht** — das Pushen passiert manuell bzw. ueber den
CI-Gate-Hinweis.

> Verifikations-Grundsatz: Live-DB-Zustand IMMER gegen den echten Pfad pruefen
> (`supabase migration list --linked` / `supabase db push --dry-run`), nie gegen
> Annahmen. Diese Liste ist der erwartete Soll-Stand, kein Ersatz fuer den
> Live-Abgleich.

## A) PENDING APPLY — muss noch auf die Live-DB gepusht werden

### 1. `20260603100000_security_hardening_followup.sql` — NOCH NICHT angewendet
- Inhalt: `delete_account()` mit explizitem `auth.uid()`-Guard
  (`EX_USER_REQUIRED`); expliziter `revoke ... from authenticated` auf
  `touch_chat_session(uuid)` (Guertel + Hosentraeger zum globalen Revoke).
- Status: Die Migration-Datei selbst notiert im Header "NOCH NICHT angewendet".
- Aktion: per `supabase db push` bzw. Management-API nachziehen. Rein additiv +
  idempotent → gefahrloses Re-Apply.

### 2. `20260604120000_lifetime_increment_rpcs.sql` — NEU, PENDING APPLY
- Inhalt: `increment_lifetime_stats(p_water, p_steps, p_meals, p_weight_logs,
  p_workouts)` (atomares `col = col + p_x`) und `record_workout_day(p_day)`
  (persistente Streak-Fortschreibung aus `last_workout_date`). Beide
  security definer, `set search_path = public`, `grant execute ... to
  authenticated`, upsert legt `lifetime_stats`-Zeile bei Erst-Usern an.
- Status: Migration in diesem Commit erstellt, **noch nicht auf Live-DB**.
- Client-Wiring: erfolgt in der **Integrations-Welle**
  (`lib/src/services/lifetime_stats_sync.dart`,
  `lib/src/services/daily_log_sync.dart`) — NICHT in diesem Commit.
- Aktion: nach Merge `supabase db push`. Bis dahin nutzt der Client weiter den
  read-modify-write-Pfad (kein Bruch, nur kein atomares Increment).

## B) Live-DB == Repo bestaetigen (Drift-Verdacht / Out-of-band gepatcht)

Diese Migrationen wurden teils out-of-band per Management-API gepatcht, um
Produktions-Bugs schnell zu fixen. Repo und Live-DB **muessen abgeglichen**
werden, damit der CI-Drift-Gate nicht auf historische Differenzen anschlaegt:

### 3. `20260602120000_profiles_weight_goal.sql`
- Fuegt `profiles.weight_goal` (+ Check-Constraint) hinzu. ProfileSync liest UND
  schreibt die Spalte; eine frische DB ohne sie wirft beim Profil-Save eine
  `PostgrestException` (Onboarding-Loop). Idempotent.
- Verifizieren: existiert `profiles.weight_goal` inkl.
  `profiles_weight_goal_check` auf der Live-DB? Falls per Hotfix gesetzt: ist die
  Constraint-Wertemenge identisch zur Repo-Definition?

### 4. `20260602120100_regrant_chat_session_rpcs.sql` (Chat-Grants)
- Re-Grant der Chat-Session-RPCs (`list_chat_sessions`,
  `ensure_default_chat_session`, `create_chat_session`, `rename_chat_session`,
  `delete_chat_session`) an `authenticated`. Noetig, weil
  `20260517220000_security_hardening.sql` zuvor alle Function-Grants von
  `authenticated` revoked.
- Verifizieren: tragen die fuenf RPCs auf der Live-DB tatsaechlich
  `EXECUTE`-Grant fuer `authenticated`? `touch_chat_session` bleibt bewusst
  service-role-only.

## CI-Gate (Drift-Erkennung)

`.github/workflows/security.yml` → Job **`supabase-migration-drift`**:
- Laeuft nur, wenn `SUPABASE_ACCESS_TOKEN` **und** `SUPABASE_PROJECT_REF` als
  Repo-Secrets gesetzt sind (optional: `SUPABASE_DB_PASSWORD`). Fehlt ein
  Secret → Schritt wird **sauber uebersprungen** (`::notice::`), CI bleibt gruen.
- Bei vorhandenem Secret: `supabase link` + `supabase db push --dry-run`. Wird
  eine pending Migration erkannt (Ausgabe enthaelt `Would push` /
  `Applying migration` / `pending`) → **Job failt**, damit keine nicht-gepushte
  Migration unbemerkt in `main` landet.

## Naechste Schritte
1. `20260603100000_security_hardening_followup.sql` auf Live-DB pushen.
2. `20260604120000_lifetime_increment_rpcs.sql` nach Integrations-Welle pushen.
3. `weight_goal`- und Chat-Grant-Migrationen gegen Live-DB abgleichen (Punkt B).
4. Sobald (1)-(3) erledigt: `supabase db push --dry-run` muss leer laufen →
   CI-Drift-Gate bleibt gruen.
