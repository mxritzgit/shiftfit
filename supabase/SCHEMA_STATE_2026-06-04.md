# Supabase Schema-State — Stand 2026-06-04 (abgeglichen)

Festgehalten: **Live-DB == Repo** für alle Migrationen, gegen den echten Katalog
verifiziert. Grundlage für den CI-Drift-Gate (`supabase-migration-drift` in
`.github/workflows/security.yml`).

> Verifikations-Grundsatz: Live-DB-Zustand IMMER gegen den echten Pfad prüfen
> (Katalog-Query / `supabase db push --dry-run`), nie gegen Annahmen.

## Abgleich-Ergebnis (2026-06-04)

Beim Live-Abgleich zeigte sich: Die `supabase_migrations.schema_migrations`-Historie
stand still bei `20260518000100`, obwohl viele spätere Objekte **out-of-band** per
Management-API eingespielt waren (Hotfixes). Zwei Migrationen waren auf der Live-DB
jedoch **gar nicht** angewandt und wurden erst jetzt nachgezogen:
`20260523000000_onboarding_fields` und `20260530091000_user_recipes`.

Vorgehen: SQL der fehlenden/ausstehenden Migrationen idempotent per Management-API
(`/v1/projects/{ref}/database/query`, PAT + Browser-UA wegen Cloudflare) angewandt,
danach die `schema_migrations`-Historie auf alle Repo-Versionen gebackfillt.

### Verifizierter Live-Zustand (Katalog-Query bestätigt)
| Migration | Objekt(e) | Live |
|-----------|-----------|------|
| 20260523000000_onboarding_fields | `profiles.activity_level`, `profiles.target_weight_kg` | ✅ |
| 20260530090000_streak_and_weekly_plan | `lifetime_stats.current_streak/longest_streak/last_workout_date`, Tabelle `weekly_plans` | ✅ |
| 20260530091000_user_recipes | Tabelle `user_recipes` + RLS (`*_own`) + `authenticated`-Grants | ✅ |
| 20260602120000_profiles_weight_goal | `profiles.weight_goal` (+ Check) | ✅ |
| 20260602120100_regrant_chat_session_rpcs | EXECUTE-Grant der 5 Chat-RPCs an `authenticated` | ✅ |
| 20260602120200_delete_account_rpc | `delete_account()` | ✅ |
| 20260603100000_security_hardening_followup | `delete_account()` mit `EX_USER_REQUIRED`-Guard; `touch_chat_session` NICHT an `authenticated` | ✅ |
| 20260604120000_lifetime_increment_rpcs | `increment_lifetime_stats(...)` + `record_workout_day(date)`, `authenticated`-Grant | ✅ |

`schema_migrations`-Historie reicht jetzt lückenlos bis `20260604120000` →
`supabase db push --dry-run` läuft leer, CI-Drift-Gate bleibt grün.

## CI-Gate (Drift-Erkennung)

`.github/workflows/security.yml` → Job **`supabase-migration-drift`**:
- Läuft nur mit Repo-Secrets `SUPABASE_ACCESS_TOKEN` **und** `SUPABASE_PROJECT_REF`
  (optional `SUPABASE_DB_PASSWORD`). Fehlt ein Secret → Schritt wird **sauber
  übersprungen** (`::notice::`), CI bleibt grün.
- Mit Secret: `supabase link` + `supabase db push --dry-run`; erkennt der Lauf eine
  pending Migration → **Job failt**, damit keine nicht-gepushte Migration unbemerkt
  in `main` landet.

## Offen
- Repo-Secrets `SUPABASE_ACCESS_TOKEN` + `SUPABASE_PROJECT_REF` setzen, um den
  Drift-Gate-Job in CI zu aktivieren (ohne sie: sauberer Skip).
- Client-Wiring der neuen RPCs (`lifetime_stats_sync` / `daily_log_sync`) erfolgt in
  der Integrations-Welle (separat).
