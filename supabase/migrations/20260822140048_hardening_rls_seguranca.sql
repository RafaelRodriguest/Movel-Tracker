-- Corrige lacunas de segurança encontradas em auditoria (skills supabase +
-- supabase-postgres-best-practices) sobre RLS/grants versionados desde a
-- baseline.

-- 1) "Leitura pública de sites" não tinha `TO`, então valia pra qualquer
-- role, inclusive `anon` — com a anon key embutida no APK, qualquer um
-- conseguia ler a tabela sites inteira sem login. O app só depende da
-- policy "Autenticados leem sites" (TO authenticated), então a pública
-- pode ser removida sem quebrar nada.
drop policy if exists "Leitura pública de sites" on public.sites;

-- 2) "Escrita autenticada" não tinha `FOR` (valia pra INSERT/UPDATE/DELETE
-- também), usava `auth.role()` (deprecated) e não tinha `WITH CHECK`.
-- Isso permitia que QUALQUER usuário autenticado (inclusive role='geral')
-- escrevesse em qualquer site. O app só faz UPDATE em sites, e isso já é
-- coberto por "cell_owner atualiza sites" (restrita a role='cell_owner').
drop policy if exists "Escrita autenticada" on public.sites;

-- 3) "Autenticados leem audit" deixava qualquer usuário autenticado ler o
-- audit log de todo mundo. O app nunca lê audit_log no cliente; restringe
-- a leitura a cell_owner, mesmo padrão usado em sites.
drop policy if exists "Autenticados leem audit" on public.audit_log;

create policy "cell_owner le audit" on public.audit_log
  for select
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'cell_owner'
    )
  );

-- 4) GRANT ALL para anon/authenticated deixava a RLS como única barreira.
-- Reduz para os privilégios que cada role realmente usa.
revoke all on public.sites from anon, authenticated;
grant select on public.sites to anon, authenticated;
grant update on public.sites to authenticated;

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;

revoke all on public.audit_log from anon, authenticated;
grant select, insert on public.audit_log to authenticated;

revoke all on public.sites_import from anon, authenticated;

-- 5) Funções sem search_path fixo ficam vulneráveis a search_path hijacking.
alter function public.get_email_by_login(p_login text) set search_path = '';
alter function public.set_updated_at() set search_path = '';
