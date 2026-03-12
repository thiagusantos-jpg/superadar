-- Endurecimento de segurança: RLS operacional + policies de Storage

-- 1) RLS em tabelas operacionais
alter table public.historico_mercado enable row level security;
alter table public.fila_precos_pendentes enable row level security;

-- Limpeza idempotente de policies antigas
drop policy if exists "dashboard_read_historico_mercado" on public.historico_mercado;
drop policy if exists "robot_insert_historico_mercado" on public.historico_mercado;
drop policy if exists "dashboard_read_fila_precos_pendentes" on public.fila_precos_pendentes;

-- Leitura mínima para dashboard (clientes anon/authenticated)
create policy "dashboard_read_historico_mercado"
on public.historico_mercado
for select
to anon, authenticated
using (true);

create policy "dashboard_read_fila_precos_pendentes"
on public.fila_precos_pendentes
for select
to anon, authenticated
using (true);

-- Escrita do robô (backend com JWT de service role)
create policy "robot_insert_historico_mercado"
on public.historico_mercado
for insert
to service_role
with check (true);

-- 2) Policies de Storage para bucket prints_concorrentes
drop policy if exists "backend_write_prints_concorrentes" on storage.objects;
drop policy if exists "public_read_prints_concorrentes" on storage.objects;

create policy "backend_write_prints_concorrentes"
on storage.objects
for insert
to service_role
with check (bucket_id = 'prints_concorrentes');

-- Leitura pública NÃO habilitada por padrão.
-- Só habilite a policy abaixo se houver requisito explícito de acesso público:
--
-- create policy "public_read_prints_concorrentes"
-- on storage.objects
-- for select
-- to public
-- using (bucket_id = 'prints_concorrentes');

