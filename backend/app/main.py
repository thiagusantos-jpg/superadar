import asyncio
import os
import requests
from datetime import datetime
from pathlib import Path
from playwright.async_api import async_playwright
from config import TELEGRAM_TOKEN, TELEGRAM_CHAT_ID, ENDERECO_LOJA
from services.supabase_service import SupabaseService

supabase_svc = SupabaseService()


def enviar_telegram(mensagem: str, caminho_foto: str = None):
    """Envia mensagem e foto via Telegram"""
    try:
        url_msg = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        requests.post(
            url_msg,
            data={"chat_id": TELEGRAM_CHAT_ID, "text": mensagem, "parse_mode": "Markdown"},
            timeout=10
        )

        if caminho_foto and os.path.exists(caminho_foto):
            url_foto = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendPhoto"
            with open(caminho_foto, 'rb') as foto:
                requests.post(
                    url_foto,
                    data={"chat_id": TELEGRAM_CHAT_ID},
                    files={"photo": foto},
                    timeout=10
                )
    except Exception as e:
        print(f"Erro ao enviar Telegram: {e}")


async def capturar_ifood(page, url_concorrente: str, termo_busca: str, ean_produto: str):
    """Captura preço de produto no iFood de concorrente"""
    try:
        # 1. Navegar para iFood e configurar endereço
        await page.goto("https://www.ifood.com.br/", timeout=30000)
        await page.wait_for_timeout(2000)

        # 2. Buscar pelo campo de endereço
        try:
            await page.click("button:has-text('Endereço')")
            await page.wait_for_timeout(1000)
            await page.fill("input[placeholder*='rua'], input[placeholder*='Endereço']", ENDERECO_LOJA)
            await page.wait_for_timeout(2000)
            # Selecionar primeira sugestão
            await page.click("li[role='option']")
            await page.wait_for_timeout(2000)
        except Exception as e:
            print(f"Erro ao configurar endereço: {e}")

        # 3. Navegar para loja do concorrente
        await page.goto(url_concorrente, timeout=30000)
        await page.wait_for_timeout(3000)

        # 4. Buscar produto
        try:
            search_input = await page.query_selector("input[placeholder*='Busque'], input[placeholder*='Pesquise']")
            if search_input:
                await search_input.fill(termo_busca)
                await page.keyboard.press("Enter")
                await page.wait_for_timeout(3000)
        except Exception as e:
            print(f"Erro ao buscar produto: {e}")
            return None

        # 5. Extrair preço
        try:
            preco_raw = await page.inner_text(".product-card__price, [data-testid='product-price']")
            preco_float = float(preco_raw.replace("R$", "").replace(",", ".").strip())
        except Exception as e:
            print(f"Erro ao extrair preço: {e}")
            return None

        # 6. Capturar screenshot
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        nome_arquivo = f"prints_{ean_produto}_{timestamp}.png"
        diretorio_prints = Path("backend/prints")
        diretorio_prints.mkdir(exist_ok=True)
        caminho_completo = diretorio_prints / nome_arquivo

        await page.screenshot(path=str(caminho_completo))

        # 7. Upload para Supabase Storage
        url_publica = supabase_svc.upload_print(nome_arquivo)

        # 8. Inserir no banco de dados
        supabase_svc.inserir_historico_mercado(ean_produto, preco_float, url_publica)

        # 9. Verificar se há sugestão automática (gatilho do banco)
        preco_atual = supabase_svc.obter_produto_preco_atual(ean_produto)
        if preco_atual and preco_float < preco_atual:
            diferenca = preco_atual - preco_float
            percentual = (diferenca / preco_atual) * 100

            msg = f"""🚨 **ALERTA DE PREÇO ABAIXO** 🚨
📦 Produto: {termo_busca}
🏪 Seu preço: R$ {preco_atual:.2f}
🔻 Concorrente: R$ {preco_float:.2f}
💔 Diferença: -R$ {diferenca:.2f} ({percentual:.1f}%)
⏰ {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}"""
        else:
            msg = f"""✅ **CAPTURA REALIZADA**
📦 Produto: {termo_busca}
💰 Preço detectado: R$ {preco_float:.2f}
⏰ {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}"""

        enviar_telegram(msg, str(caminho_completo))

        # 10. Limpar arquivo local
        if caminho_completo.exists():
            caminho_completo.unlink()

        return preco_float

    except Exception as e:
        print(f"Erro ao capturar ifood: {e}")
        return None


async def main():
    """Função principal do robô"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()

        # Exemplos de capturas (configurar conforme necessário)
        alvos = [
            {
                "url_concorrente": "https://www.ifood.com.br/delivery/sao-paulo-sp/st-marche-vila-madalena",
                "termo_busca": "Azeite Andorinha 500ml",
                "ean": "7896001700141"
            },
            # Adicionar mais alvos conforme necessário
        ]

        for alvo in alvos:
            try:
                await capturar_ifood(
                    page,
                    alvo["url_concorrente"],
                    alvo["termo_busca"],
                    alvo["ean"]
                )
            except Exception as e:
                print(f"Erro ao processar alvo {alvo['ean']}: {e}")
                enviar_telegram(f"❌ Erro ao capturar {alvo['termo_busca']}: {e}")

        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
