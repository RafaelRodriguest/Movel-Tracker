-- A migration 20260822140048 travou search_path='' em get_email_by_login por
-- segurança (evita search_path hijacking), mas o corpo referenciava "profiles"
-- sem qualificar o schema — com search_path vazio isso quebra em runtime com
-- "relation profiles does not exist" (42P01), derrubando o login de todo mundo.
create or replace function public.get_email_by_login(p_login text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select email from public.profiles where login = p_login limit 1;
$$;
