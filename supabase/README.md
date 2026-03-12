# Supabase - SuperRadar

## Arquivos
- `supabase/migrations/20260101_init_superadar.sql`: schema inicial (extensões, tabelas, função, trigger e índices).
- `supabase/migrations/20260102_security_rls_storage.sql`: hardening de segurança (RLS em tabelas operacionais + policies de Storage).
- `supabase/seeds/initial_data.sql`: carga de dados de exemplo (`categorias` e `produtos`).

## Ordem de aplicação (SQL Editor)
1. Abra o **SQL Editor** no projeto Supabase.
2. Execute `supabase/migrations/20260101_init_superadar.sql`.
3. Execute `supabase/migrations/20260102_security_rls_storage.sql`.
4. Após sucesso das migrations, execute `supabase/seeds/initial_data.sql`.

## Observações
- As migrations criam extensões e policies de modo idempotente (`IF NOT EXISTS` e `DROP POLICY IF EXISTS`).
- A leitura pública do bucket `prints_concorrentes` **não** é habilitada por padrão; só habilite se houver requisito explícito.
- O seed usa `ON CONFLICT` para permitir reexecução sem duplicar registros.
