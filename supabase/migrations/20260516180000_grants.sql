-- GRANTs fuer die authenticated-Rolle. Ohne diese Grants kann selbst
-- ein eingeloggter User trotz passender RLS-Policy nicht auf die
-- public-Tabellen schreiben - Postgres macht die Privilege-Pruefung
-- VOR der RLS-Pruefung. Symptom: 42501 "permission denied for table X".
--
-- Im Supabase-Dashboard-Tabelleneditor passiert das automatisch; bei
-- raw SQL via Management-API/psql muss man die Grants selber setzen.

-- Schema-Level (USAGE noetig damit ueber das Schema gequeried werden darf).
grant usage on schema public to anon, authenticated, service_role;

-- Volle CRUD-Rechte fuer eingeloggte User. RLS-Policies schraenken
-- danach welche Rows tatsaechlich sichtbar/aenderbar sind.
grant select, insert, update, delete on all tables in schema public
  to authenticated;

-- service_role bekommt sowieso alles (Edge Functions, Admin).
grant all on all tables in schema public to service_role;

-- Sequenzen (z.B. fuer serial PKs) brauchen separate Grants.
grant usage, select on all sequences in schema public to authenticated;
grant all on all sequences in schema public to service_role;

-- Funktionen: authenticated darf alle plpgsql-Funktionen aufrufen die
-- in public liegen (z.B. fuer custom RPC).
grant execute on all functions in schema public to authenticated, service_role;

-- Default Privileges: alle KUENFTIGEN Tabellen/Sequenzen/Funktionen
-- die im public-Schema vom postgres-Owner erstellt werden, kriegen
-- die Grants automatisch. Damit muss diese Migration nicht jedes Mal
-- nachgezogen werden wenn neue Tabellen dazukommen.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant all on tables to service_role;
alter default privileges in schema public
  grant usage, select on sequences to authenticated;
alter default privileges in schema public
  grant all on sequences to service_role;
alter default privileges in schema public
  grant execute on functions to authenticated, service_role;
