# SuperRadar 🎯

> Sistema inteligente de monitoramento de preços em tempo real para proteção de margem de lucro

**Localização Alvo**: Vila Madalena, São Paulo - SP
**Objetivo**: Monitorizar concorrentes hyper-locais via iFood, capturar provas visuais e municiar compras para negociações

---

## 📋 Índice

- [Arquitetura](#-arquitetura)
- [Requisitos](#-requisitos)
- [Setup Rápido](#-setup-rápido)
- [Configuração Detalhada](#-configuração-detalhada)
- [Como Usar](#-como-usar)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Arquitetura

```
┌─────────────────────┐
│   GitHub Actions    │  (Executa diariamente 06:30 BRT)
│  robo_precos.py     │
└──────────┬──────────┘
           │
           ├─► Playwright + iFood
           │
           └─► Supabase (SQL + Storage)
                   │
           ┌───────┼───────┐
           │       │       │
          SQL    Storage  Telegram
         (DB)   (Prints)   (Alerts)
           │
       ┌───┴────┐
       │ Views  │
       │ Alerts │
       └────────┘
```

**Stack:**
- **Backend**: Python 3.10 (Playwright, Supabase SDK)
- **Database**: PostgreSQL (Supabase) + PostGIS
- **Storage**: Supabase Storage (prints_concorrentes)
- **Messaging**: Telegram Bot API
- **CI/CD**: GitHub Actions (Serverless)
- **Frontend**: HTML5 + Tailwind CSS (Vercel) - *próxima fase*

---

## 📦 Requisitos

- Python 3.10+
- Conta Supabase (grátis)
- Token Bot Telegram
- Repositório GitHub
- Git

---

## ⚡ Setup Rápido

### 1. Clonar Repositório
```bash
git clone https://github.com/seu-usuario/superadar.git
cd superadar
```

### 2. Configurar Supabase
```bash
# Siga as instruções em: supabase/README.md
# Você vai precisar de:
# - SUPABASE_URL
# - SUPABASE_KEY (anon)
```

### 3. Criar Bot Telegram
```bash
# No Telegram:
# 1. Fale com @BotFather
# 2. /newbot
# 3. Copie o TOKEN
# 4. Crie um grupo e adicione seu bot
# 5. Obtenha o CHAT_ID (@userinfobot)
```

### 4. Setup Local (Desenvolvimento)
```bash
# Instalar dependências
cd backend
pip install -r requirements.txt
playwright install chromium

# Criar arquivo .env (usar .env.example como base)
cp .env.example .env

# Editar .env com suas credenciais
nano .env
```

### 5. GitHub Secrets
```bash
# No repositório GitHub:
# Settings > Secrets and variables > Actions > New repository secret

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
TELEGRAM_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
```

---

## 📖 Configuração Detalhada

### Passo 1: Supabase
Veja: [supabase/README.md](supabase/README.md)

**Resumo:**
1. Criar projeto em supabase.com
2. Executar schema.sql no SQL Editor
3. Criar bucket `prints_concorrentes` (público)
4. Copiar SUPABASE_URL e SUPABASE_KEY

### Passo 2: Telegram Bot
```bash
# @BotFather (no Telegram)
/newbot
# Siga as instruções e copie o token

# Para obter CHAT_ID:
# 1. Crie um grupo de teste
# 2. Adicione seu bot
# 3. Envie uma mensagem
# 4. Use @userinfobot para descobrir o ID
```

### Passo 3: GitHub Actions
```bash
# No repositório:
1. Settings > Secrets and variables > Actions
2. Add repository secrets (4 variáveis acima)
3. A action está em: .github/workflows/main.yml
4. Executa diariamente às 06:30 BRT (09:30 UTC)
```

### Passo 4: Testar Localmente
```bash
cd backend
python -m app.main
```

---

## 🎯 Como Usar

### Executar Manualmente
```bash
# Local
cd backend
python -m app.main

# GitHub Actions
# Na aba "Actions" do GitHub, clique em "Run workflow"
```

### Adicionar Novo Produto
```sql
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES ('7896001700141', 'Azeite Andorinha 500ml', 1, 28.50, 34.90);
```

### Adicionar Novo Concorrente
```sql
INSERT INTO concorrentes (nome, url_ifood)
VALUES ('St Marche', 'https://www.ifood.com.br/delivery/sao-paulo-sp/st-marche-vila-madalena');
```

### Ver Alertas Pendentes
```sql
SELECT * FROM v_alertas_ativos;
```

### Ver Últimas Capturas
```sql
SELECT * FROM v_ultimas_capturas LIMIT 10;
```

---

## 🔍 Monitoramento

### Views Disponíveis (Supabase SQL)

#### `v_ultimas_capturas`
Últimos preços detectados por produto:
```sql
SELECT * FROM v_ultimas_capturas;
```

#### `v_alertas_ativos`
Preços que precisam revisão:
```sql
SELECT * FROM v_alertas_ativos;
```

### Telegram Alerts
O bot envia automaticamente:
- ✅ Confirmação de captura
- 🚨 Alerta se concorrente baixou preço
- ❌ Erros durante execução

---

## 🐛 Troubleshooting

### Erro: "Playwright timeout"
```bash
# Aumentar timeout na captura
# Edite em backend/app/main.py:
# await page.goto(..., timeout=30000)
```

### Erro: "Supabase connection refused"
- Verificar se SUPABASE_URL está correto
- Verificar se SUPABASE_KEY é a chave "anon"
- Confirmar que o projeto está ativo no Supabase

### Erro: "Telegram bot not responding"
- Verificar TELEGRAM_TOKEN com @BotFather
- Confirmar que o bot está no grupo (TELEGRAM_CHAT_ID)
- Usar @userinfobot para validar CHAT_ID

### Erro: "Arquivo não encontrado: prints/"
```bash
# Criar diretório
mkdir -p backend/prints
```

### Action no GitHub não executa
1. Verificar Secrets em Settings > Secrets and variables > Actions
2. Verificar se cron está correto em .github/workflows/main.yml
3. Habilitar Actions em Settings > Actions > General

---

## 📊 Estrutura de Pastas

```
superadar/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py          # Variáveis de ambiente
│   │   ├── main.py            # Script principal (robo)
│   │   └── services/
│   │       ├── __init__.py
│   │       └── supabase_service.py  # Interação com DB
│   ├── prints/                # Diretório de screenshots (temp)
│   ├── requirements.txt        # Dependências Python
│   └── .env.example            # Template de variáveis
├── .github/
│   └── workflows/
│       └── main.yml           # GitHub Actions schedule
├── supabase/
│   ├── schema.sql             # Schema do banco + triggers
│   └── README.md              # Instruções Supabase
├── frontend/                  # (Próxima fase)
│   └── index.html
├── PRD_SUPERADAR_V1.md        # Requisitos do produto
└── README.md                  # Este arquivo
```

---

## 🚀 Próximas Fases

- **Fase 3**: Frontend Dashboard (HTML + Tailwind)
- **Fase 4**: Autenticação e RBAC
- **Fase 5**: Mobile App (React Native)

---

## 📞 Suporte

Para dúvidas ou bugs:
1. Verificar [Troubleshooting](#-troubleshooting)
2. Consultar documentação:
   - [Supabase Docs](https://supabase.com/docs)
   - [Playwright Docs](https://playwright.dev)
   - [Telegram Bot API](https://core.telegram.org/bots/api)
3. Abrir issue no GitHub

---

**Versão**: 1.0
**Última atualização**: Março 2026
**Mantido por**: SuperRadar Team
