-- DSGVO Art. 17 (Recht auf Löschung) / Apple 5.1.1(v): der User muss sein
-- Konto + alle Daten selbst löschen können. delete_account() löscht die
-- auth.users-Zeile des aufrufenden Users; alle App-Tabellen hängen per
-- `on delete cascade` an auth.users(id) und werden dadurch mitgelöscht.
--
-- security definer, damit der (nur tabellen-berechtigte) authenticated-Rolle
-- die auth.users-Zeile löschen darf. search_path gepinnt; auth.users explizit
-- schema-qualifiziert. Nur der eigene Account (auth.uid()) ist löschbar.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
