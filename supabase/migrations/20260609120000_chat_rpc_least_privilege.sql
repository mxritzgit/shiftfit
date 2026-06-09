-- Least-Privilege-Härtung der Chat-Session-RPCs (Audit 2026-06-09).
-- Rein additiv + idempotent. Behebt:
--
--  MEDIUM (2026-06-09): ensure_default_chat_session(uuid) war live für PUBLIC
--    (und damit anon) ausführbar UND akzeptierte ein beliebiges p_user_id,
--    dessen coalesce(p_user_id, auth.uid())-Pfad den null-Guard umging. Folge:
--    ein unauthentifizierter Aufrufer mit dem öffentlichen anon-Key konnte über
--    den SECURITY-DEFINER-INSERT eine chat_sessions-Zeile in einem FREMDEN
--    Account anlegen (RLS-Bypass) bzw. eine fremde Session-UUID zurückbekommen
--    und den FK auf auth.users als User-Existenz-/UUID-Oracle nutzen.
--
--  LOW (2026-06-09): 5 weitere Chat-RPCs (create/delete/rename/list_chat_session*,
--    get_chat_quota_today) trugen residual PUBLIC EXECUTE. Ursache:
--    20260517220000_security_hardening.sql revoked EXECUTE nur von anon (Z.13)
--    und authenticated (Z.23), NIE von public — anon erbte EXECUTE daher über
--    PUBLIC. Heute harmlos (alle nutzen auth.uid() direkt), aber Least-Privilege-
--    Verstoß und fragil. Konsistent zu claim_chat_quota/touch_chat_session/
--    delete_account, die genau diesen expliziten public-Revoke bereits haben.
--
-- Bewusst NICHT geändert: touch_chat_session/claim_chat_quota erhalten KEINEN
-- in-function auth.uid()-Filter. Sie laufen ausschließlich über service_role
-- (auth.uid() = null); ein harter Filter würde den Edge-Function-Pfad brechen.
-- Ihre Absicherung ist (live verifiziert) der service_role-only-Grant.

-- ---------------------------------------------------------------------------
-- 1) PUBLIC/anon EXECUTE entziehen; authenticated/service_role explizit behalten
-- ---------------------------------------------------------------------------
revoke execute on function public.ensure_default_chat_session(uuid) from public, anon;
revoke execute on function public.create_chat_session(text)         from public, anon;
revoke execute on function public.delete_chat_session(uuid)         from public, anon;
revoke execute on function public.rename_chat_session(uuid, text)   from public, anon;
revoke execute on function public.list_chat_sessions()              from public, anon;
revoke execute on function public.get_chat_quota_today(integer)     from public, anon;

grant execute on function public.ensure_default_chat_session(uuid) to authenticated, service_role;
grant execute on function public.create_chat_session(text)         to authenticated, service_role;
grant execute on function public.delete_chat_session(uuid)         to authenticated, service_role;
grant execute on function public.rename_chat_session(uuid, text)   to authenticated, service_role;
grant execute on function public.list_chat_sessions()              to authenticated, service_role;
grant execute on function public.get_chat_quota_today(integer)     to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2) In-Function-Guard für ensure_default_chat_session: ein eingeloggter Client
--    (auth.uid() gesetzt) darf p_user_id NICHT auf einen fremden User zeigen
--    lassen. service_role hat auth.uid() = null und darf p_user_id frei setzen
--    (Edge-Function-Pfad, ruft mit dem service_role-Key + p_user_id). Der
--    App-Client ruft die RPC ohnehin ohne Parameter auf -> auth.uid().
-- ---------------------------------------------------------------------------
create or replace function public.ensure_default_chat_session(
  p_user_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_id  uuid;
begin
  if p_user_id is not null
     and auth.uid() is not null
     and p_user_id <> auth.uid() then
    raise exception 'EX_FORBIDDEN' using errcode = '42501';
  end if;

  v_uid := coalesce(p_user_id, auth.uid());
  if v_uid is null then
    raise exception 'EX_USER_REQUIRED' using errcode = '22023';
  end if;

  select id into v_id
    from public.chat_sessions
   where user_id = v_uid
   order by last_message_at desc
   limit 1;

  if v_id is null then
    insert into public.chat_sessions (user_id, title)
      values (v_uid, 'Neue Unterhaltung')
      returning id into v_id;
  end if;

  return v_id;
end;
$$;

-- create or replace bewahrt zwar die bestehende ACL, aber zur Sicherheit hier
-- nochmal deterministisch festziehen (idempotent).
revoke execute on function public.ensure_default_chat_session(uuid) from public, anon;
grant execute on function public.ensure_default_chat_session(uuid) to authenticated, service_role;
