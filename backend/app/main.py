from __future__ import annotations

import asyncio
import json
import os
from dataclasses import dataclass
from pathlib import Path

from playwright.async_api import async_playwright

from backend.app.config import Settings
from backend.app.services.ifood_scraper import capturar_preco_produto, configurar_endereco
from backend.app.services.supabase_service import SupabaseService
from backend.app.services.telegram_service import TelegramService


@dataclass(frozen=True)
class AlvoMonitoramento:
    url_concorrente: str
    termo_busca: str
    ean_produto: str
    concorrente_id: str | None = None


def carregar_alvos() -> list[AlvoMonitoramento]:
    alvos_raw = os.getenv("SCAN_TARGETS_JSON", "[]")
    parsed = json.loads(alvos_raw)
    return [AlvoMonitoramento(**item) for item in parsed]


async def run() -> None:
    settings = Settings.from_env()
    alvos = carregar_alvos()

    if not alvos:
        raise ValueError(
            "Nenhum alvo configurado. Defina SCAN_TARGETS_JSON com lista de objetos contendo "
            "url_concorrente, termo_busca e ean_produto."
        )

    supabase_service = SupabaseService(settings.supabase_url, settings.supabase_key)
    telegram_service = TelegramService(settings.telegram_token, settings.telegram_chat_id)

    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=True)
        page = await browser.new_page()
        await configurar_endereco(page, settings.endereco_loja)

        for alvo in alvos:
            captura = await capturar_preco_produto(
                page=page,
                url_concorrente=alvo.url_concorrente,
                termo_busca=alvo.termo_busca,
                ean_produto=alvo.ean_produto,
                print_dir=Path("prints"),
            )
            remote_path = f"prints/{captura.local_screenshot.name}"
            url_publica = supabase_service.upload_print(
                bucket="prints_concorrentes",
                local_file_path=captura.local_screenshot,
                remote_path=remote_path,
            )

            supabase_service.insert_historico_mercado(
                ean=alvo.ean_produto,
                preco_detectado=captura.preco_detectado,
                url_print=url_publica,
                concorrente_id=alvo.concorrente_id,
            )

            mensagem = (
                f"🚨 *Nova Captura (Vila Madalena)*\n"
                f"📦 {alvo.termo_busca}\n"
                f"💰 Preço detectado: R$ {captura.preco_detectado:.2f}"
            )
            telegram_service.send_message(mensagem)
            telegram_service.send_photo(captura.local_screenshot)

        await browser.close()


if __name__ == "__main__":
    asyncio.run(run())
