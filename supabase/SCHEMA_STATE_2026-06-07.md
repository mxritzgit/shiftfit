# Supabase Schema-State — Stand 2026-06-07 (re-verifiziert)

Festgehalten: **Live-DB == Repo** für alle Migrationen, am 2026-06-07 gegen den
echten Katalog der Live-DB (`ftoozzvmduptrvrrrshb`) verifiziert. Grundlage für den
CI-Drift-Gate (`supabase-migration-drift` in `.github/workflows/security.yml`).

> Verifikations-Grundsatz: Live-DB-Zustand IMMER gegen den echten Pfad prüfen
> (Katalog-Query via Management-API), nie gegen Annahmen.

## Abgleich-Ergebnis (2026-06-07)

`supabase_migrations.schema_migrations` enthält **lückenlos alle 19 Repo-Versionen**
von `20260516150000` bis `20260604160000` — identische Liste, identische Reihenfolge
wie `ls supabase/migrations`. Es gibt **keine Drift**: kein Repo-Eintrag fehlt in der
Historie, `db push` wäre ein No-Op.

Damit sind die in früheren Migrations-Kommentaren als „NOCH NICHT angewendet (PENDING
APPLY)" markierten Migrationen (`20260603100000`, `20260604120000` und die folgenden
bis `20260604160000`) **überholt** — sie sind angewendet und registriert. Die
betroffenen Kommentare wurden am 2026-06-07 entsprechend richtiggestellt.

### Verifizierter Live-Zustand (Katalog-Query bestätigt, 2026-06-07)
| Migration | Objekt(e) | Live | Registriert |
|-----------|-----------|------|-------------|
| 20260603100000_security_hardening_followup | `delete_account()` mit `EX_USER_REQUIRED`-Guard; `touch_chat_session(uuid)` NICHT an `authenticated` ausführbar | ✅ | ✅ |
| 20260604120000_lifetime_increment_rpcs | `increment_lifetime_stats(int,int,int,int,int)` + `record_workout_day(date)` | ✅ | ✅ |
| 20260604130000_favorite_meals_pinned | `favorite_meals.pinned boolean not null default false` | ✅ | ✅ |
| 20260604140000_profiles_diet_preference | `profiles.diet_preference text` + `profiles_diet_preference_check` | ✅ | ✅ |
| 20260604150000_local_day_keys | `logged_meals.local_day` + `caffeine_entries.local_day` (+ Indizes) | ✅ | ✅ |
| 20260604160000_workout_logging | Tabelle `workout_sets` + RLS an + 4 `*_own`-Policies + `authenticated`-Grants | ✅ | ✅ |

(Frühere Objekte bis `20260602120200` waren bereits im Stand 2026-06-04 als live
verifiziert; `user_recipes` + `weekly_plans` ebenfalls vorhanden.)

## CI-Gate (Drift-Erkennung)

`.github/workflows/security.yml` → Job **`supabase-migration-drift`**:
- Läuft nur mit Repo-Secrets `SUPABASE_ACCESS_TOKEN` **und** `SUPABASE_PROJECT_REF`.
  Fehlt ein Secret → Schritt wird **sauber übersprungen** (`::notice::`), CI bleibt
  grün (Forks/PRs ohne Secret-Zugriff machen den Build nicht rot).
- Mit Secrets: fragt die Live-Migrations-Historie über die **Management-API**
  (`POST /v1/projects/{ref}/database/query` auf `supabase_migrations.schema_migrations`,
  Browser-User-Agent wegen Cloudflare 1010) ab und vergleicht sie gegen die
  Dateinamen in `supabase/migrations/`. Ist eine Repo-Migration **nicht** in der
  Historie registriert → **Job failt**. Bewusst KEIN `supabase db push --dry-run`
  mehr: das brauchte ein `SUPABASE_DB_PASSWORD`-Secret + DB-Login; der Management-API-
  Weg kommt mit dem ohnehin nötigen PAT aus.

## Offen / Entscheidung
- **Repo-Secret `SUPABASE_ACCESS_TOKEN` setzen, um den Gate-Job in CI scharf zu
  schalten.** Sicherheits-Trade-off bewusst lassen: Der `sbp_`-PAT ist
  **account-weit** (kann DDL auf jedem Projekt des Accounts) und kann von Supabase
  nicht projekt-scoped ausgestellt werden. In einem **öffentlichen** Repo ist das
  ein realer Blast-Radius, falls er je aus den Actions-Secrets exfiltriert wird
  (nur über Push/Workflow-Änderung auf `main` möglich — Fork-PRs erhalten das Secret
  nicht). Ohne das Secret bleibt der Gate-Job ein sauberer Skip; die Drift-Prüfung
  läuft dann weiterhin manuell/lokal über die Management-API (wie am 2026-06-07).
- Client-Wiring der neuen RPCs (`lifetime_stats_sync` / `daily_log_sync`) erfolgt in
  der Integrations-Welle (separat).
