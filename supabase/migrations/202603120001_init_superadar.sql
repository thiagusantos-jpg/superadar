-- SuperRadar - init schema + automações + segurança

-- 1) Extensões
create extension if not exists postgis;
create extension if not exists "uuid-ossp";

-- 2) Tabelas estruturais
create table if not exists public.categorias (
    id serial primary key,
    nome_interno text unique not null,
    margem_alvo_percentual numeric(5, 2) not null default 15.00,
    created_at timestamptz not null default now()
);

create table if not exists public.produtos (
    id uuid primary key default uuid_generate_v4(),
    ean text unique not null,
    nome text not null,
    categoria_id integer references public.categorias(id),
    preco_custo numeric(10, 2) not null,
    preco_venda_atual numeric(10, 2) not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.concorrentes (
    id uuid primary key default uuid_generate_v4(),
    nome text not null,
    url_ifood text,
    localizacao geography(point, 4326),
    created_at timestamptz not null default now()
);

-- 3) Tabelas operacionais
create table if not exists public.historico_mercado (
    id bigserial primary key,
    created_at timestamptz not null default now(),
    ean text not null,
    preco_detectado numeric(10, 2) not null,
    url_print text,
    concorrente_id uuid references public.concorrentes(id)
);

create table if not exists public.fila_precos_pendentes (
    id uuid primary key default uuid_generate_v4(),
    produto_id uuid references public.produtos(id),
    preco_sugerido numeric(10, 2),
    motivo text,
    status text not null default 'pendente' check (status in ('pendente', 'aprovado', 'rejeitado')),
    created_at timestamptz not null default now()
);

-- 4) Índices
create index if not exists idx_produtos_ean on public.produtos(ean);
create index if not exists idx_historico_ean_created_at on public.historico_mercado(ean, created_at desc);
create index if not exists idx_fila_status_created_at on public.fila_precos_pendentes(status, created_at desc);

-- 5) Trigger de atualização de updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trigger_produtos_set_updated_at on public.produtos;
create trigger trigger_produtos_set_updated_at
before update on public.produtos
for each row execute function public.set_updated_at();

-- 6) Função de sugestão de preço (com proteção de margem/custo)
create or replace function public.sugerir_preco_automatico()
returns trigger as $$
declare
    v_produto_id uuid;
    v_preco_venda_atual numeric(10,2);
    v_preco_custo numeric(10,2);
    v_margem_alvo numeric(5,2);
    v_preco_minimo_margem numeric(10,2);
    v_preco_sugerido_final numeric(10,2);
    v_motivo text;
begin
    select p.id, p.preco_venda_atual, p.preco_custo, c.margem_alvo_percentual
      into v_produto_id, v_preco_venda_atual, v_preco_custo, v_margem_alvo
      from public.produtos p
      left join public.categorias c on c.id = p.categoria_id
     where p.ean = new.ean
     limit 1;

    if v_produto_id is null then
      return new;
    end if;

    if new.preco_detectado < v_preco_venda_atual then
      v_margem_alvo := coalesce(v_margem_alvo, 15.00);
      v_preco_minimo_margem := round(v_preco_custo / (1 - (v_margem_alvo / 100.0)), 2);
      v_preco_sugerido_final := least(new.preco_detectado, v_preco_venda_atual);

      if v_preco_sugerido_final < v_preco_custo then
        v_preco_sugerido_final := v_preco_custo;
        v_motivo := 'Negociar com fornecedor: preço de mercado abaixo do custo';
      elsif v_preco_sugerido_final < v_preco_minimo_margem then
        v_motivo := format(
          'Abaixo da margem alvo (%.2f%%). Revisar com compras/fornecedor',
          v_margem_alvo
        );
      else
        v_motivo := 'Concorrente baixou preço: sugerir ajuste';
      end if;

      insert into public.fila_precos_pendentes (produto_id, preco_sugerido, motivo)
      values (v_produto_id, v_preco_sugerido_final, v_motivo);
    end if;

    return new;
end;
$$ language plpgsql;

drop trigger if exists trigger_analise_precos on public.historico_mercado;
create trigger trigger_analise_precos
after insert on public.historico_mercado
for each row execute function public.sugerir_preco_automatico();

-- 7) RLS e políticas
alter table public.historico_mercado enable row level security;
alter table public.fila_precos_pendentes enable row level security;
alter table public.produtos enable row level security;
alter table public.categorias enable row level security;
alter table public.concorrentes enable row level security;

-- Leitura (dashboard / anon autenticado)
drop policy if exists "read_historico" on public.historico_mercado;
create policy "read_historico"
on public.historico_mercado for select
to anon, authenticated
using (true);

drop policy if exists "read_fila_precos" on public.fila_precos_pendentes;
create policy "read_fila_precos"
on public.fila_precos_pendentes for select
to anon, authenticated
using (true);

drop policy if exists "read_produtos" on public.produtos;
create policy "read_produtos"
on public.produtos for select
to anon, authenticated
using (true);

drop policy if exists "read_categorias" on public.categorias;
create policy "read_categorias"
on public.categorias for select
to anon, authenticated
using (true);

drop policy if exists "read_concorrentes" on public.concorrentes;
create policy "read_concorrentes"
on public.concorrentes for select
to anon, authenticated
using (true);

-- Escrita restrita (backend com service_role)
drop policy if exists "write_historico_service_role" on public.historico_mercado;
create policy "write_historico_service_role"
on public.historico_mercado for insert
to service_role
with check (true);

drop policy if exists "write_fila_service_role" on public.fila_precos_pendentes;
create policy "write_fila_service_role"
on public.fila_precos_pendentes for insert
to service_role
with check (true);

-- 8) Storage bucket + policies
insert into storage.buckets (id, name, public)
values ('prints_concorrentes', 'prints_concorrentes', true)
on conflict (id) do nothing;

-- leitura pública dos prints
drop policy if exists "public_read_prints" on storage.objects;
create policy "public_read_prints"
on storage.objects for select
to public
using (bucket_id = 'prints_concorrentes');

-- escrita somente service role
drop policy if exists "service_role_write_prints" on storage.objects;
create policy "service_role_write_prints"
on storage.objects for insert
to service_role
with check (bucket_id = 'prints_concorrentes');
