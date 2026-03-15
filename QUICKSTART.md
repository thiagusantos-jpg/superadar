# ⚡ SuperRadar - Guia de Início Rápido

Siga estes passos para estar operacional em **15 minutos**:

## 1️⃣ Criar Projeto Supabase (5 min)

```bash
# Abra em seu navegador:
# https://supabase.com/dashboard

# Clique em "New Project"
# - Name: superadar
# - Password: (gere uma forte)
# - Region: South America (São Paulo)
# - Clique em "Create New Project"

# Aguarde ~5 minutos...
```

## 2️⃣ Executar SQL Schema (2 min)

Na dashboard do Supabase:

```bash
# 1. SQL Editor (menu lateral)
# 2. Clique em "New Query"
# 3. Copie todo conteúdo de: supabase/schema.sql
# 4. Cole no editor
# 5. Clique em "Run"
```

✅ Banco pronto!

## 3️⃣ Criar Storage Bucket (1 min)

Na dashboard do Supabase:

```bash
# 1. Storage (menu lateral)
# 2. Create a new bucket
# 3. Name: prints_concorrentes
# 4. ✓ Make it public
# 5. Create bucket
```

## 4️⃣ Copiar API Keys (1 min)

Na dashboard do Supabase:

```bash
# 1. Settings (menu lateral)
# 2. API
# 3. Copie:
#    - Project URL → SUPABASE_URL
#    - anon public → SUPABASE_KEY
```

**Salve em um bloco de notas!**

## 5️⃣ Criar Bot Telegram (3 min)

No Telegram (App ou Web):

```bash
# 1. Procure por: @BotFather
# 2. /newbot
# 3. Escolha um nome
# 4. Escolha um username (@nome_bot)
# 5. Copie o TOKEN gerado
# 6. Crie um grupo e adicione seu bot
```

**Para obter CHAT_ID:**

```bash
# 1. No grupo, procure por: @userinfobot
# 2. Envie uma mensagem
# 3. Ele mostra seu User ID (CHAT_ID)
```

**Salve o TOKEN e CHAT_ID!**

## 6️⃣ Configurar GitHub (2 min)

```bash
# 1. Seu repositório GitHub
# 2. Settings > Secrets and variables > Actions
# 3. Click "New repository secret"
# 4. Adicione estes 4 secrets:

SUPABASE_URL = (do passo 4)
SUPABASE_KEY = (do passo 4)
TELEGRAM_TOKEN = (do passo 5)
TELEGRAM_CHAT_ID = (do passo 5)
```

✅ Pronto! O bot vai rodar automaticamente todo dia às 06:30 AM (horário de Brasília)

## 🧪 Testar Localmente

```bash
# Opcional - para testar antes de fazer push

cd backend
cp .env.example .env

# Edite .env com seus valores
nano .env

# Instale dependências
pip install -r requirements.txt
playwright install chromium

# Execute o bot
python -m app.main
```

## ✅ Status

Verifique se está funcionando:

1. **Supabase Dashboard**:
   - Tabelas aparecem em "SQL Editor"
   - Bucket `prints_concorrentes` em "Storage"

2. **GitHub Actions**:
   - Vá para "Actions"
   - Clique em "SuperRadar Daily Scan"
   - Clique em "Run workflow" para testar
   - Acompanhe a execução

3. **Telegram**:
   - Você receberá mensagens de confirmação no grupo

## 🚀 Adicionar Produtos

No Supabase SQL Editor:

```sql
-- Azeite (categoria 1)
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES ('7896001700141', 'Azeite Andorinha 500ml', 1, 28.50, 34.90);

-- Café (categoria 2)
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES ('7891000000191', 'Café Pilão 500g', 2, 12.00, 16.90);

-- Açúcar (categoria 3)
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES ('7896345600011', 'Açúcar Cristal 1kg', 3, 3.50, 5.90);
```

## 🛒 Adicionar Concorrentes

No Supabase SQL Editor:

```sql
INSERT INTO concorrentes (nome, url_ifood)
VALUES
    ('St Marche', 'https://www.ifood.com.br/delivery/sao-paulo-sp/st-marche-vila-madalena'),
    ('Pão de Queijo Delivery', 'https://www.ifood.com.br/delivery/sao-paulo-sp/pao-de-queijo-delivery-vila-madalena');
```

## 📊 Ver Alertas

No Supabase SQL Editor:

```sql
-- Ver preços pendentes de revisão
SELECT * FROM v_alertas_ativos;

-- Ver últimas capturas
SELECT * FROM v_ultimas_capturas;
```

## 🎯 Próximos Passos

- [x] Backend operacional
- [x] Database configurado
- [ ] Adicionar mais alvos (produtos/concorrentes)
- [ ] Customizar horário de execução
- [ ] Dashboard frontend (próxima fase)

---

**Tudo pronto?** Consulte [README.md](README.md) para guia completo!

**Dúvidas?** Veja seção "Troubleshooting" em [README.md](README.md)
