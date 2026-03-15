# 🚀 SuperRadar - Configuração do Supabase

## Pré-requisitos
- Conta no [Supabase](https://supabase.com)
- Acesso ao projeto criado

## Passo 1: Criar Projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e faça login
2. Clique em "New Project"
3. Preencha os dados:
   - **Name**: `superadar`
   - **Database Password**: Gere uma senha forte
   - **Region**: `South America (São Paulo)`
4. Clique em "Create New Project" e aguarde ~5 minutos

## Passo 2: Executar o SQL Schema

1. No painel do Supabase, vá para **SQL Editor**
2. Clique em "New Query"
3. Copie todo o conteúdo do arquivo `schema.sql`
4. Cole no editor e clique em "Run"

✅ Seu banco de dados está pronto!

## Passo 3: Criar Storage Bucket

1. No menu lateral, vá para **Storage**
2. Clique em "Create a new bucket"
3. **Name**: `prints_concorrentes`
4. Marque a opção "Make it public"
5. Clique em "Create bucket"

## Passo 4: Gerar API Keys

1. Vá para **Settings** > **API**
2. Você verá:
   - `Project URL` → Copie como `SUPABASE_URL`
   - `anon public` → Copie como `SUPABASE_KEY`

## Passo 5: Adicionar Dados Iniciais (Opcional)

Para testar, você pode inserir produtos manualmente:

```sql
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES
    ('7896001700141', 'Azeite Andorinha 500ml', 1, 28.50, 34.90),
    ('7891000000191', 'Café Pilão 500g', 2, 12.00, 16.90);
```

## Verificação Final

Execute esta query para verificar se tudo está funcionando:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Você deve ver as tabelas:
- `categorias`
- `concorrentes`
- `fila_precos_pendentes`
- `historico_mercado`
- `produtos`

## Próximos Passos

1. Configure as variáveis de ambiente no GitHub (veja instruções no README principal)
2. Configure seu bot do Telegram
3. Deploy automático estará pronto!

---

**Dúvidas?** Consulte a [documentação do Supabase](https://supabase.com/docs)
