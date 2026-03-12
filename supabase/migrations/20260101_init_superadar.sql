-- Migration inicial do SuperRadar

-- 1. Extensões
create extension if not exists postgis;
create extension if not exists "uuid-ossp";

-- 2. Tabelas
create table if not exists public.categorias (
  id serial primary key,
  nome_interno text not null unique,
  margem_alvo_percentual numeric(5,2) not null default 15.00,
  created_at timestamptz not null default now()
);

create table if not exists public.produtos (
  id uuid primary key default uuid_generate_v4(),
  ean text not null unique,
  nome text not null,
  categoria_id integer references public.categorias(id),
  preco_custo numeric(10,2) not null,
  preco_venda_atual numeric(10,2) not null,
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

create table if not exists public.historico_mercado (
  id bigserial primary key,
  ean text not null,
  preco_detectado numeric(10,2) not null,
  url_print text,
  concorrente_id uuid references public.concorrentes(id),
  created_at timestamptz not null default now()
);

create table if not exists public.fila_precos_pendentes (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid not null references public.produtos(id),
  preco_sugerido numeric(10,2),
  motivo text,
  status text not null default 'pendente' check (status in ('pendente', 'aprovado', 'rejeitado')),
  created_at timestamptz not null default now()
);

-- utilitário para updated_at de produtos
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trigger_produtos_set_updated_at on public.produtos;
create trigger trigger_produtos_set_updated_at
before update on public.produtos
for each row execute function public.set_updated_at();

-- 3. Função de sugestão automática de preços
create or replace function public.sugerir_preco_automatico()
returns trigger
language plpgsql
as $$
declare
  v_produto_id uuid;
  v_preco_atual numeric(10,2);
  v_preco_custo numeric(10,2);
  v_margem_alvo numeric(5,2);
  v_preco_minimo_margem numeric(10,2);
  v_preco_sugerido numeric(10,2);
  v_motivo text;
begin
  select p.id, p.preco_venda_atual, p.preco_custo, c.margem_alvo_percentual
    into v_produto_id, v_preco_atual, v_preco_custo, v_margem_alvo
    from public.produtos p
    left join public.categorias c on c.id = p.categoria_id
   where p.ean = new.ean
   limit 1;

  if v_produto_id is null then
    return new;
  end if;

  if new.preco_detectado < v_preco_atual then
    v_margem_alvo := coalesce(v_margem_alvo, 15.00);
    v_preco_minimo_margem := round(v_preco_custo / (1 - (v_margem_alvo / 100.0)), 2);
    v_preco_sugerido := least(new.preco_detectado, v_preco_atual);

    if v_preco_sugerido < v_preco_custo then
      v_preco_sugerido := v_preco_custo;
      v_motivo := 'Preço concorrente abaixo do custo: negociar fornecedor';
    elsif v_preco_sugerido < v_preco_minimo_margem then
      v_motivo := format('Preço abaixo da margem alvo de %.2f%%', v_margem_alvo);
    else
      v_motivo := 'Concorrente reduziu preço: sugerir ajuste';
    end if;

    insert into public.fila_precos_pendentes (produto_id, preco_sugerido, motivo)
    values (v_produto_id, v_preco_sugerido, v_motivo);
  end if;

  return new;
end;
$$;

-- 4. Trigger de análise no histórico de mercado
drop trigger if exists trigger_analise_precos on public.historico_mercado;
create trigger trigger_analise_precos
after insert on public.historico_mercado
for each row execute function public.sugerir_preco_automatico();

-- 5. Índices mínimos
create index if not exists idx_produtos_ean on public.produtos (ean);
create index if not exists idx_historico_mercado_ean on public.historico_mercado (ean);
create index if not exists idx_historico_mercado_created_at on public.historico_mercado (created_at desc);
create index if not exists idx_fila_precos_status on public.fila_precos_pendentes (status);
create index if not exists idx_fila_precos_created_at on public.fila_precos_pendentes (created_at desc);
