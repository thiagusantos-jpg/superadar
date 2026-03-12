# Supabase - SuperRadar

## Arquivos
- `supabase/migrations/20260101_init_superadar.sql`: schema inicial (extensões, tabelas, função, trigger e índices).
- `supabase/seeds/initial_data.sql`: carga de dados de exemplo (`categorias` e `produtos`).

## Ordem de aplicação (SQL Editor)
1. Abra o **SQL Editor** no projeto Supabase.
2. Execute primeiro `supabase/migrations/20260101_init_superadar.sql`.
3. Após sucesso da migration, execute `supabase/seeds/initial_data.sql`.

## Observações
- A migration cria as extensões `postgis` e `uuid-ossp` com `IF NOT EXISTS`.
- O seed usa `ON CONFLICT` para permitir reexecução sem duplicar registros.
