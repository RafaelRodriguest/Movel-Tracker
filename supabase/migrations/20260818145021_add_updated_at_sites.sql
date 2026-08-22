-- Registra a data/hora da última alteração de cada site.
-- O trigger é a fonte da verdade: cobre qualquer caminho de escrita (fotos,
-- campos operacionais, edições manuais no dashboard) sem depender do app.

-- Sem DEFAULT nesta etapa: `add column ... default now()` preenche as linhas
-- existentes com now(), o backfill abaixo não acharia nenhum NULL e todo site
-- passaria a alegar ter sido atualizado no instante da migration.
alter table public.sites
  add column if not exists updated_at timestamptz;

-- Linhas já existentes partem da data de criação, não de "agora"
update public.sites set updated_at = created_at where updated_at is null;

-- DEFAULT só depois do backfill, valendo para linhas novas
alter table public.sites
  alter column updated_at set default now();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists sites_set_updated_at on public.sites;

create trigger sites_set_updated_at
  before update on public.sites
  for each row
  execute function public.set_updated_at();
