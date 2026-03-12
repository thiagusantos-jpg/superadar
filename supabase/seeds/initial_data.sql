insert into public.categorias (nome_interno, margem_alvo_percentual)
values
  ('Azeite', 20.00),
  ('Cafe', 18.00),
  ('Acucar', 15.00)
on conflict (nome_interno) do update
set margem_alvo_percentual = excluded.margem_alvo_percentual;

insert into public.produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
values
  ('7896001700141', 'Azeite Extra Virgem Andorinha 500ml', (select id from public.categorias where nome_interno = 'Azeite'), 28.50, 34.90),
  ('7891000053508', 'Cafe Pilao Tradicional 500g', (select id from public.categorias where nome_interno = 'Cafe'), 12.40, 18.90),
  ('7891910000197', 'Acucar Uniao Refinado 1kg', (select id from public.categorias where nome_interno = 'Acucar'), 3.85, 5.49)
on conflict (ean) do update
set
  nome = excluded.nome,
  categoria_id = excluded.categoria_id,
  preco_custo = excluded.preco_custo,
  preco_venda_atual = excluded.preco_venda_atual;
