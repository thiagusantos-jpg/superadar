# Supabase - SuperRadar

## Ordem de execução
1. Execute `supabase/migrations/202603120001_init_superadar.sql` no SQL Editor do projeto Supabase.
2. Execute `supabase/seeds/initial_data.sql` para carga inicial.

## O que essa migration cria
- Extensões `postgis` e `uuid-ossp`.
- Tabelas de domínio, operação e índices.
- Trigger `trigger_analise_precos` com função `sugerir_preco_automatico`.
- RLS e policies para separar leitura do dashboard e escrita de backend.
- Bucket `prints_concorrentes` e policies de leitura/escrita em `storage.objects`.

## Segurança de chaves
- `SUPABASE_KEY` no backend/Actions deve ser a **service role key**.
- Nunca exponha service role key no frontend.
- Frontend deve usar apenas a publishable/anon key.

## Convenção de uploads
- Caminho remoto: `prints/<ean>_<timestamp>.png`.
- Content type: `image/png`.
