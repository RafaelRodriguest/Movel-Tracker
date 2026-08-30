-- Tabela usada só pelo workflow keep-supabase-alive.yml: um INSERT diário
-- conta como atividade de banco de dados e evita a pausa automática do
-- free tier (SELECT sozinho não estava sendo suficiente).
create table public.keepalive_ping (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now()
);

alter table public.keepalive_ping enable row level security;

create policy "anon pode inserir ping"
  on public.keepalive_ping
  for insert
  to anon
  with check (true);
