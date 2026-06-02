-- Re-Grant der Chat-Session-RPCs an authenticated.
-- 20260517220000_security_hardening.sql führt "revoke execute on all functions in
-- schema public from authenticated" (Z. 23) NACH der Erstellung dieser RPCs aus
-- (20260517170000_chat_sessions.sql) und grantet sie nicht neu. Der Client ruft sie
-- aber als authenticated auf (lib/src/services/coach_chat_service.dart:29,49,66,86,102)
-- -> erwartbar 42501 permission denied, Chat-Liste/Session-Verwaltung kaputt.
-- Diese RPCs sind security-definer + user-scoped (auth.uid()), daher sicher an
-- authenticated zu granten. touch_chat_session bleibt bewusst service_role-only
-- (intern, kein Client-Aufruf). Idempotent: grant ist bei vorhandenem Recht ein No-Op.

grant execute on function public.list_chat_sessions()            to authenticated;
grant execute on function public.ensure_default_chat_session(uuid) to authenticated;
grant execute on function public.create_chat_session(text)         to authenticated;
grant execute on function public.rename_chat_session(uuid, text)   to authenticated;
grant execute on function public.delete_chat_session(uuid)         to authenticated;
