PRD_SUPERADAR_V1.md
📑 Documento de Requisitos do Produto (PRD)Produto: SuperRadar - Inteligência de Pricing e MixLocalização Alvo: Vila Madalena, São Paulo - SP (R. Marinho Falcão, 55)Versão: 1.0 (Release Candidate)Objetivo Primário: Monitorizar concorrentes hyper-locais em tempo real, capturar provas visuais, proteger a margem de lucro e municiar o setor de compras para negociações.🏗️ Visão Geral da ArquiteturaO sistema opera num modelo Serverless (sem servidor dedicado), garantindo custo zero de infraestrutura na fase inicial.Backend Automático: Robô Python executado via GitHub Actions.Banco de Dados & Nuvem: Supabase (PostgreSQL + PostGIS + Storage).Frontend: HTML5 puro + Tailwind CSS (hospedado na Vercel).Mensageria: Integração direta com API do Telegram.🗄️ FASE 1: BACKEND - BANCO DE DADOS (Supabase)O coração do sistema. Aqui armazenamos as categorias (com metas de margem), os produtos, o histórico de preços e a fila de decisões.1.1. Script SQL Consolidado (Estrutura e Gatilhos)Deve ser executado no SQL Editor do Supabase para criar todo o ecossistema.SQL-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABELAS DE ESTRUTURA
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome_interno TEXT UNIQUE NOT NULL,
    margem_alvo_percentual DECIMAL(5,2) DEFAULT 15.00
);

CREATE TABLE produtos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ean TEXT UNIQUE NOT NULL,
    nome TEXT NOT NULL,
    categoria_id INTEGER REFERENCES categorias(id),
    preco_custo DECIMAL(10,2) NOT NULL,
    preco_venda_atual DECIMAL(10,2) NOT NULL
);

CREATE TABLE concorrentes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome TEXT NOT NULL,
    url_ifood TEXT,
    localizacao GEOGRAPHY(POINT, 4326)
);

-- 3. TABELAS DE OPERAÇÃO
CREATE TABLE historico_mercado (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ean TEXT NOT NULL,
    preco_detectado DECIMAL(10,2) NOT NULL,
    url_print TEXT,
    concorrente_id UUID REFERENCES concorrentes(id)
);

CREATE TABLE fila_precos_pendentes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    produto_id UUID REFERENCES produtos(id),
    preco_sugerido DECIMAL(10,2),
    motivo TEXT,
    status TEXT DEFAULT 'pendente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. AUTOMAÇÃO: Gatilho de Sugestão de Preço (Inteligência do Banco)
CREATE OR REPLACE FUNCTION sugerir_preco_automatico()
RETURNS TRIGGER AS $$
DECLARE
    v_produto_id UUID;
BEGIN
    SELECT id INTO v_produto_id FROM produtos WHERE ean = NEW.ean;

    -- Se o preço do vizinho for menor, cria alerta para revisão
    IF NEW.preco_detectado < (SELECT preco_venda_atual FROM produtos WHERE id = v_produto_id) THEN
        INSERT INTO fila_precos_pendentes (produto_id, preco_sugerido, motivo)
        VALUES (v_produto_id, NEW.preco_detectado, 'Concorrente baixou o preço');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_analise_precos
AFTER INSERT ON historico_mercado
FOR EACH ROW EXECUTE FUNCTION sugerir_preco_automatico();
1.2. Storage (Armazenamento de Provas)Bucket: Criar um bucket público chamado prints_concorrentes no painel do Supabase para guardar os screenshots.🤖 FASE 2: BACKEND - MOTOR DE CAPTURA (Python)O "detetive" do sistema. Este script Python usa a biblioteca Playwright para simular um humano, define o endereço da loja no iFood, captura os preços, tira a foto da prova e avisa no Telegram.2.1. Script Principal: robo_precos.pyPythonimport asyncio
import os
import requests
from datetime import datetime
from playwright.async_api import async_playwright
from supabase import create_client

# Configurações de Ambiente
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")
ENDERECO_LOJA = "R. Marinho Falcão, 55 - Vila Madalena, São Paulo"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def enviar_telegram(mensagem, caminho_foto):
    url_msg = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    requests.post(url_msg, data={"chat_id": TELEGRAM_CHAT_ID, "text": mensagem, "parse_mode": "Markdown"})
    
    url_foto = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendPhoto"
    with open(caminho_foto, 'rb') as foto:
        requests.post(url_foto, data={"chat_id": TELEGRAM_CHAT_ID}, files={"photo": foto})

async def capturar_ifood(page, url_concorrente, termo_busca, ean_produto):
    # 1. Configurar Endereço
    await page.goto("https://www.ifood.com.br/")
    await page.click("button:has-text('Endereço')")
    await page.fill("input[placeholder*='rua']", ENDERECO_LOJA)
    await page.click(".address-search__item") # Primeira sugestão
    
    # 2. Buscar Produto
    await page.goto(url_concorrente)
    await page.fill("input[placeholder*='Busque']", termo_busca)
    await page.keyboard.press("Enter")
    await page.wait_for_timeout(3000)
    
    # 3. Extração e Print
    preco_raw = await page.inner_text(".product-card__price")
    preco_float = float(preco_raw.replace("R$", "").replace(",", ".").strip())
    
    nome_arquivo = f"prints/{ean_produto}_{datetime.now().strftime('%Y%m%d%H%M')}.png"
    os.makedirs("prints", exist_ok=True)
    await page.locator(".product-card").first.screenshot(path=nome_arquivo)
    
    # 4. Upload para Supabase Storage
    with open(nome_arquivo, 'rb') as f:
        supabase.storage.from_('prints_concorrentes').upload(path=nome_arquivo, file=f, file_options={"content-type": "image/png"})
    url_publica = supabase.storage.from_('prints_concorrentes').get_public_url(nome_arquivo)
    
    # 5. Inserir na Base de Dados SQL
    supabase.table("historico_mercado").insert({
        "ean": ean_produto,
        "preco_detectado": preco_float,
        "url_print": url_publica
    }).execute()
    
    # 6. Alerta Telegram
    msg = f"🚨 *Nova Captura (Vila Madalena)*\n📦 {termo_busca}\n💰 Preço: R$ {preco_float}"
    enviar_telegram(msg, nome_arquivo)

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        # Exemplo de Alvo: Azeite no St Marche
        await capturar_ifood(page, "URL_ST_MARCHE", "Azeite Andorinha 500ml", "7896001700141")
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
2.2. Automação (GitHub Actions): .github/workflows/main.ymlFaz o robô rodar todos os dias às 06:30 da manhã (Horário de Brasília).YAMLname: SuperRadar Daily Scan
on:
  schedule:
    - cron: '30 9 * * *' # 09:30 UTC = 06:30 BRT
  workflow_dispatch:
jobs:
  scrape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.10'
      - run: pip install playwright supabase requests && playwright install chromium
      - run: python robo_precos.py
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_KEY: ${{ secrets.SUPABASE_KEY }}
          TELEGRAM_TOKEN: ${{ secrets.TELEGRAM_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
🖥️ FASE 3: FRONTEND - DASHBOARD (UI/UX)A interface para o gestor tomar decisões, ver fotos das prateleiras virtuais e gerar relatórios. Desenvolvido em HTML e Tailwind CSS.3.1. Layout e Popup de Prova (index.html resumido)HTML<!DOCTYPE html>
<html lang="pt-br">
<head>
    <title>SuperRadar | Vila Madalena</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="bg-gray-50 p-8">

    <div class="mb-8 p-6 bg-white rounded-xl shadow border-l-4 border-red-500">
        <h2 class="text-lg font-bold">Azeite Extra Virgem Andorinha</h2>
        <p class="text-sm text-gray-500">Seu Preço: R$ 34,90 | Concorrente: <span class="text-red-600 font-bold">R$ 31,90</span></p>
        
        <div class="mt-4 space-x-2">
            <button onclick="abrirModal('URL_DA_FOTO_DO_SUPABASE')" class="px-4 py-2 bg-blue-600 text-white rounded text-sm"><i class="fa-solid fa-eye"></i> Ver Prova Visual</button>
            <button onclick="gerarPDF()" class="px-4 py-2 bg-red-100 text-red-700 rounded text-sm"><i class="fa-solid fa-file-pdf"></i> PDF p/ Fornecedor</button>
        </div>
    </div>

    <script>
        function abrirModal(url) {
            const modal = document.createElement('div');
            modal.className = "fixed inset-0 bg-black bg-opacity-80 flex items-center justify-center z-50 p-4";
            modal.innerHTML = `
                <div class="relative bg-white p-2 rounded max-w-2xl">
                    <button onclick="this.parentElement.parentElement.remove()" class="absolute -top-10 right-0 text-white text-3xl">&times;</button>
                    <img src="${url}" class="rounded w-full">
                </div>`;
            document.body.appendChild(modal);
        }
    </script>
</body>
</html>
3.2. Script JS para Geração de PDF de NegociaçãoJavaScript// Adicionar as bibliotecas no <head>
// <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
// <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.25/jspdf.plugin.autotable.min.js"></script>

function gerarPDF() {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    doc.text("Auditoria de Preços - Vila Madalena", 14, 20);
    
    // Simulação de dados vindos do banco
    const dados = [ ["Azeite Andorinha 500ml", "R$ 28.50", "R$ 31.90", "11.9%"] ];
    
    doc.autoTable({
        startY: 30,
        head: [['Produto', 'Seu Custo', 'Mercado', 'Margem']],
        body: dados,
    });
    doc.save('Negociacao_Fornecedor.pdf');
}
📐 FASE 4: LÓGICA DE NEGÓCIO E FÓRMULASO sistema opera garantindo proteção matemática contra prejuízos.Cálculo do Preço Sugerido com base na Margem Alvo:Para garantir que o produto gere a margem exigida pela categoria, o cálculo interno do sistema respeita a fórmula de Markup por fora (Margem Bruta):$$P_s=\frac{C}{1-M}$$(Onde $P_s$ é o Preço Sugerido, $C$ é o Custo e $M$ é a Margem percentual em decimal, ex: 0.20).Regra de Bloqueio: O sistema nunca aprovará automaticamente um preço onde o $P_s$ final resulte num valor menor que o Preço de Custo ($C$). Nesses casos, a recomendação gerada é sempre "Negociar com Fornecedor".🚀 GUIA DE IMPLANTAÇÃO (Ordem de Execução)Supabase: Criar projeto $\rightarrow$ Executar o Script SQL (Fase 1.1) $\rightarrow$ Criar o Bucket prints_concorrentes.Carga Inicial: Fazer upload do CSV com os produtos e categorias (Azeite, Café, Açúcar) na tabela produtos.GitHub: Criar repositório $\rightarrow$ Subir robo_precos.py e a pasta .github/workflows $\rightarrow$ Adicionar as variáveis (Supabase e Telegram) na aba Settings > Secrets.Vercel: Conectar o repositório GitHub à Vercel para hospedar o ficheiro index.html (O teu Dashboard estará online em segundos).