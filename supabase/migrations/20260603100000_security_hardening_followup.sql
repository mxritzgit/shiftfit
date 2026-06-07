-- Security-Hardening-Followup (Audit 2026-06-03). Rein additiv + idempotent.
-- Status: am 2026-06-07 gegen die Live-DB verifiziert — angewendet UND in
-- supabase_migrations.schema_migrations registriert (delete_account-Guard live,
-- touch_chat_session fuer authenticated revoked).
--
-- 1) delete_account(): expliziter auth.uid()-Guard, wie ihn bereits alle
--    Chat-Session-RPCs haben (EX_USER_REQUIRED). delete_account() war der
--    einzige security-definer-RPC OHNE diesen Guard. Ohne ihn würde ein
--    unerwarteter Aufruferkontext mit non-null auth.uid() unmittelbar die
--    auth.users-Zeile löschen; mit leerem auth.uid() liefe ein
--    `delete ... where id = null` (löscht 0 Zeilen, aber unsauber). Defense in
--    depth — Verhalten für echte authenticated-Aufrufe unverändert.
--
-- 2) touch_chat_session(uuid): expliziter `revoke ... from authenticated`
--    (Gürtel + Hosenträger). Die Funktion ist service-role-only, verließ sich
--    bisher aber allein auf den globalen Revoke aus
--    20260517220000_security_hardening.sql. Würden Migrationen out-of-order
--    angewendet, wäre sie kurzzeitig für authenticated aufrufbar. claim_chat_quota,
--    consume_edge_rate_limit und prune_edge_rate_limits haben diesen expliziten
--    Revoke bereits — touch_chat_session zieht hiermit nach.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'EX_USER_REQUIRED' using errcode = '22023';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;

revoke execute on function public.touch_chat_session(uuid)
  from public, anon, authenticated;
grant execute on function public.touch_chat_session(uuid) to service_role;
