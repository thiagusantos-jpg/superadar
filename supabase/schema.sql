-- ============================================================================
-- SUPERADAR DATABASE SCHEMA
-- Autor: SuperRadar Team
-- Data: 2026
-- Objetivo: Monitorizar concorrentes hyper-locais em tempo real
-- ============================================================================

-- 1. EXTENSÕES NECESSÁRIAS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABELAS DE ESTRUTURA
-- ============================================================================

-- Tabela: categorias
-- Descrição: Categorias de produtos com meta de margem alvo
CREATE TABLE IF NOT EXISTS categorias (
    id SERIAL PRIMARY KEY,
    nome_interno TEXT UNIQUE NOT NULL,
    margem_alvo_percentual DECIMAL(5,2) DEFAULT 15.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: produtos
-- Descrição: Catálogo de produtos monitorados
CREATE TABLE IF NOT EXISTS produtos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ean TEXT UNIQUE NOT NULL,
    nome TEXT NOT NULL,
    categoria_id INTEGER REFERENCES categorias(id) ON DELETE SET NULL,
    preco_custo DECIMAL(10,2) NOT NULL,
    preco_venda_atual DECIMAL(10,2) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: concorrentes
-- Descrição: Lojas/concorrentes monitorados no iFood
CREATE TABLE IF NOT EXISTS concorrentes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome TEXT NOT NULL,
    url_ifood TEXT UNIQUE,
    localizacao GEOGRAPHY(POINT, 4326),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABELAS DE OPERAÇÃO
-- ============================================================================

-- Tabela: historico_mercado
-- Descrição: Registro de todos os preços capturados dos concorrentes
CREATE TABLE IF NOT EXISTS historico_mercado (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ean TEXT NOT NULL,
    preco_detectado DECIMAL(10,2) NOT NULL,
    url_print TEXT,
    concorrente_id UUID REFERENCES concorrentes(id) ON DELETE SET NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_historico_ean ON historico_mercado(ean);
CREATE INDEX IF NOT EXISTS idx_historico_concorrente ON historico_mercado(concorrente_id);
CREATE INDEX IF NOT EXISTS idx_historico_created ON historico_mercado(created_at);

-- Tabela: fila_precos_pendentes
-- Descrição: Fila de decisões sobre ajustes de preço
CREATE TABLE IF NOT EXISTS fila_precos_pendentes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    preco_sugerido DECIMAL(10,2),
    preco_atual DECIMAL(10,2),
    preco_concorrente DECIMAL(10,2),
    motivo TEXT,
    status TEXT DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_fila_status ON fila_precos_pendentes(status);
CREATE INDEX IF NOT EXISTS idx_fila_produto ON fila_precos_pendentes(produto_id);

-- 4. AUTOMAÇÃO: GATILHOS (TRIGGERS)
-- ============================================================================

-- Função: sugerir_preco_automatico
-- Descrição: Analisa novos preços do mercado e cria sugestões automáticas
CREATE OR REPLACE FUNCTION sugerir_preco_automatico()
RETURNS TRIGGER AS $$
DECLARE
    v_produto_id UUID;
    v_preco_atual DECIMAL(10,2);
    v_categoria_id INTEGER;
    v_margem_alvo DECIMAL(5,2);
    v_preco_minimo DECIMAL(10,2);
    v_preco_sugerido DECIMAL(10,2);
    v_preco_custo DECIMAL(10,2);
BEGIN
    -- Obter ID do produto pelo EAN
    SELECT id, preco_venda_atual, preco_custo, categoria_id
    INTO v_produto_id, v_preco_atual, v_preco_custo, v_categoria_id
    FROM produtos
    WHERE ean = NEW.ean AND ativo = true;

    IF v_produto_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Obter margem alvo da categoria
    SELECT margem_alvo_percentual
    INTO v_margem_alvo
    FROM categorias
    WHERE id = v_categoria_id;

    IF v_margem_alvo IS NULL THEN
        v_margem_alvo := 15.00;
    END IF;

    -- Calcular preço mínimo (custo)
    v_preco_minimo := v_preco_custo;

    -- Calcular preço sugerido usando fórmula de margem: P = C / (1 - M)
    -- Onde M é a margem em decimal (ex: 0.15 para 15%)
    v_preco_sugerido := v_preco_custo / (1 - (v_margem_alvo / 100));

    -- Se o preço do concorrente for menor que o nosso, criar sugestão
    IF NEW.preco_detectado < v_preco_atual THEN
        INSERT INTO fila_precos_pendentes (
            produto_id,
            preco_sugerido,
            preco_atual,
            preco_concorrente,
            motivo,
            status
        ) VALUES (
            v_produto_id,
            CASE
                WHEN NEW.preco_detectado > v_preco_minimo THEN NEW.preco_detectado
                ELSE v_preco_sugerido
            END,
            v_preco_atual,
            NEW.preco_detectado,
            'Concorrente baixou o preço',
            'pendente'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: trigger_analise_precos
CREATE TRIGGER trigger_analise_precos
AFTER INSERT ON historico_mercado
FOR EACH ROW
EXECUTE FUNCTION sugerir_preco_automatico();

-- Função: atualizar_updated_at
-- Descrição: Atualiza o timestamp updated_at automaticamente
CREATE OR REPLACE FUNCTION atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar updated_at
CREATE TRIGGER trigger_atualizar_produtos
BEFORE UPDATE ON produtos
FOR EACH ROW
EXECUTE FUNCTION atualizar_updated_at();

CREATE TRIGGER trigger_atualizar_categorias
BEFORE UPDATE ON categorias
FOR EACH ROW
EXECUTE FUNCTION atualizar_updated_at();

CREATE TRIGGER trigger_atualizar_concorrentes
BEFORE UPDATE ON concorrentes
FOR EACH ROW
EXECUTE FUNCTION atualizar_updated_at();

CREATE TRIGGER trigger_atualizar_fila
BEFORE UPDATE ON fila_precos_pendentes
FOR EACH ROW
EXECUTE FUNCTION atualizar_updated_at();

-- 5. DADOS INICIAIS (SEED)
-- ============================================================================

-- Inserir categorias padrão
INSERT INTO categorias (nome_interno, margem_alvo_percentual)
VALUES
    ('azeite', 20.00),
    ('cafe', 18.00),
    ('acucar', 15.00)
ON CONFLICT (nome_interno) DO NOTHING;

-- 6. SEGURANÇA E CONTROLE DE ACESSO
-- ============================================================================

-- Enable RLS se necessário (descomente conforme necessário)
-- ALTER TABLE historico_mercado ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE fila_precos_pendentes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;

-- 7. VIEWS ÚTEIS
-- ============================================================================

-- View: v_ultimas_capturas
-- Descrição: Últimos preços capturados por produto
CREATE OR REPLACE VIEW v_ultimas_capturas AS
SELECT
    p.id as produto_id,
    p.ean,
    p.nome,
    p.preco_venda_atual,
    hm.preco_detectado,
    hm.created_at,
    c.nome as concorrente,
    ROUND((hm.preco_detectado - p.preco_venda_atual)::numeric, 2) as diferenca,
    ROUND((((hm.preco_detectado - p.preco_venda_atual) / p.preco_venda_atual) * 100)::numeric, 2) as percentual_diferenca
FROM historico_mercado hm
JOIN produtos p ON p.ean = hm.ean
LEFT JOIN concorrentes c ON c.id = hm.concorrente_id
WHERE hm.created_at = (
    SELECT MAX(created_at)
    FROM historico_mercado
    WHERE ean = p.ean
)
ORDER BY hm.created_at DESC;

-- View: v_alertas_ativos
-- Descrição: Preços pendentes que requerem ação
CREATE OR REPLACE VIEW v_alertas_ativos AS
SELECT
    fp.id,
    p.nome,
    p.preco_venda_atual,
    fp.preco_concorrente,
    fp.preco_sugerido,
    fp.motivo,
    fp.created_at,
    ROUND((((fp.preco_concorrente - p.preco_venda_atual) / p.preco_venda_atual) * 100)::numeric, 2) as percentual_diferenca
FROM fila_precos_pendentes fp
JOIN produtos p ON p.id = fp.produto_id
WHERE fp.status = 'pendente'
ORDER BY fp.created_at DESC;
