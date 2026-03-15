# 📊 SuperRadar - Schema do Banco de Dados

## Visão Geral

```
categorias
    ↓
produtos ← historico_mercado → concorrentes
    ↓
fila_precos_pendentes
```

---

## Tabelas

### `categorias`
Categorias de produtos com metas de margem.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | SERIAL PK | ID único |
| `nome_interno` | TEXT UNIQUE | Nome (ex: 'azeite', 'cafe') |
| `margem_alvo_percentual` | DECIMAL(5,2) | Meta de margem (%) |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Última atualização |

**Exemplo:**
```sql
INSERT INTO categorias (nome_interno, margem_alvo_percentual)
VALUES ('azeite', 20.00);
```

---

### `produtos`
Catálogo de produtos monitorados.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID PK | ID único |
| `ean` | TEXT UNIQUE | Código de barras |
| `nome` | TEXT | Nome do produto |
| `categoria_id` | INT FK | Referência à categoria |
| `preco_custo` | DECIMAL(10,2) | Custo de compra |
| `preco_venda_atual` | DECIMAL(10,2) | Preço de venda |
| `ativo` | BOOLEAN | Ativo (padrão: true) |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Última atualização |

**Exemplo:**
```sql
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES ('7896001700141', 'Azeite Andorinha 500ml', 1, 28.50, 34.90);
```

---

### `concorrentes`
Lojas/concorrentes monitorados.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID PK | ID único |
| `nome` | TEXT | Nome da loja |
| `url_ifood` | TEXT UNIQUE | Link iFood |
| `localizacao` | GEOGRAPHY | Coordenadas (PostGIS) |
| `ativo` | BOOLEAN | Ativo (padrão: true) |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Última atualização |

**Exemplo:**
```sql
INSERT INTO concorrentes (nome, url_ifood)
VALUES ('St Marche', 'https://www.ifood.com.br/delivery/sao-paulo-sp/st-marche-vila-madalena');
```

---

### `historico_mercado`
Registro de TODAS as capturas de preço (auditoria completa).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | BIGSERIAL PK | ID único |
| `created_at` | TIMESTAMP | Data/hora da captura |
| `ean` | TEXT | EAN do produto capturado |
| `preco_detectado` | DECIMAL(10,2) | Preço encontrado no concorrente |
| `url_print` | TEXT | URL da screenshot (Supabase Storage) |
| `concorrente_id` | UUID FK | Qual loja foi monitorada |

**Índices:**
- `idx_historico_ean` - Rápido buscar por EAN
- `idx_historico_concorrente` - Rápido filtrar por loja
- `idx_historico_created` - Rápido ordenar por data

**Exemplo:**
```sql
SELECT * FROM historico_mercado
WHERE ean = '7896001700141'
ORDER BY created_at DESC
LIMIT 10;
```

---

### `fila_precos_pendentes`
Fila de DECISÕES sobre ajustes de preço (gerada automaticamente por triggers).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID PK | ID único |
| `produto_id` | UUID FK | Qual produto |
| `preco_sugerido` | DECIMAL(10,2) | Preço recomendado |
| `preco_atual` | DECIMAL(10,2) | Nosso preço atual |
| `preco_concorrente` | DECIMAL(10,2) | Preço detectado |
| `motivo` | TEXT | Por que foi criado |
| `status` | TEXT | pendente/aprovado/rejeitado |
| `created_at` | TIMESTAMP | Data da sugestão |
| `updated_at` | TIMESTAMP | Última atualização |

**Exemplo:**
```sql
SELECT * FROM fila_precos_pendentes
WHERE status = 'pendente'
ORDER BY created_at DESC;
```

---

## Triggers (Automação)

### `trigger_analise_precos`
**Quando:** Após INSERT em `historico_mercado`
**O que faz:** Analisa se o preço capturado é menor que o nosso e cria uma sugestão

**Lógica:**
```
1. Obter ID do produto pelo EAN
2. Se preço_detectado < preco_venda_atual:
   → Criar registro em fila_precos_pendentes
   → status = 'pendente'
```

**Fórmula de Sugestão:**
```
P_sugerido = Custo / (1 - Margem%)

Exemplo:
- Custo: R$ 28.50
- Margem: 20%
- P_sugerido = 28.50 / (1 - 0.20) = R$ 35.63
```

---

## Views (Consultas Úteis)

### `v_ultimas_capturas`
Últimos preços capturados por produto com análise.

```sql
SELECT * FROM v_ultimas_capturas;
```

**Retorna:**
| Coluna | Descrição |
|--------|-----------|
| `produto_id` | ID do produto |
| `ean` | Código de barras |
| `nome` | Nome do produto |
| `preco_venda_atual` | Nosso preço |
| `preco_detectado` | Preço encontrado |
| `created_at` | Data da captura |
| `concorrente` | Nome da loja |
| `diferenca` | Diferença em R$ |
| `percentual_diferenca` | Diferença em % |

---

### `v_alertas_ativos`
Preços pendentes de aprovação.

```sql
SELECT * FROM v_alertas_ativos;
```

**Retorna:**
| Coluna | Descrição |
|--------|-----------|
| `id` | ID da sugestão |
| `nome` | Nome do produto |
| `preco_venda_atual` | Nosso preço |
| `preco_concorrente` | Preço encontrado |
| `preco_sugerido` | Preço recomendado |
| `motivo` | Razão do alerta |
| `created_at` | Data da sugestão |
| `percentual_diferenca` | Diferença em % |

---

## Consultas Comuns

### Ver alertas críticos (>10% abaixo)
```sql
SELECT * FROM v_alertas_ativos
WHERE percentual_diferenca < -10
ORDER BY percentual_diferenca ASC;
```

### Produtos com mais capturas
```sql
SELECT ean, COUNT(*) as total_capturas
FROM historico_mercado
GROUP BY ean
ORDER BY total_capturas DESC;
```

### Média de preço por EAN (últimas 30 dias)
```sql
SELECT
    ean,
    AVG(preco_detectado) as media_preco,
    MIN(preco_detectado) as minimo,
    MAX(preco_detectado) as maximo
FROM historico_mercado
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY ean
ORDER BY media_preco DESC;
```

### Produtos monitorados ativos
```sql
SELECT * FROM produtos
WHERE ativo = true
ORDER BY nome;
```

### Histórico de um produto específico
```sql
SELECT
    hm.created_at,
    hm.preco_detectado,
    c.nome as concorrente,
    hm.url_print
FROM historico_mercado hm
LEFT JOIN concorrentes c ON c.id = hm.concorrente_id
WHERE hm.ean = '7896001700141'
ORDER BY hm.created_at DESC;
```

---

## Inserção de Dados

### Adicionar múltiplos produtos
```sql
INSERT INTO produtos (ean, nome, categoria_id, preco_custo, preco_venda_atual)
VALUES
    ('7896001700141', 'Azeite Andorinha 500ml', 1, 28.50, 34.90),
    ('7891000000191', 'Café Pilão 500g', 2, 12.00, 16.90),
    ('7896345600011', 'Açúcar Cristal 1kg', 3, 3.50, 5.90),
    ('78960123456789', 'Sal Refinado 1kg', 3, 1.50, 3.50);
```

### Adicionar concorrentes
```sql
INSERT INTO concorrentes (nome, url_ifood)
VALUES
    ('St Marche', 'https://www.ifood.com.br/delivery/sao-paulo-sp/st-marche-vila-madalena'),
    ('Hortifruti Extra', 'https://www.ifood.com.br/delivery/sao-paulo-sp/hortifruti-extra-vila-madalena'),
    ('Zona Verde', 'https://www.ifood.com.br/delivery/sao-paulo-sp/zona-verde-vila-madalena');
```

---

## Performance

### Índices Criados
- `idx_historico_ean` - Rápido buscar histórico por EAN
- `idx_historico_concorrente` - Rápido filtrar por loja
- `idx_historico_created` - Rápido ordenar por data
- `idx_fila_status` - Rápido filtrar pendentes

### Recomendações
1. Limpar histórico antigo periodicamente (>90 dias)
2. Arquivar fila aprovada/rejeitada mensalmente
3. Monitorar tamanho do storage de prints

---

## Backup

### Backup automático
Supabase realiza backups diários. Configure em:
**Settings > Database > Backups**

### Backup manual
```bash
# Exportar schema
pg_dump -h db.supabase.co -U postgres --schema-only > schema.sql

# Exportar dados
pg_dump -h db.supabase.co -U postgres > full_backup.sql
```

---

**Última atualização**: Março 2026
