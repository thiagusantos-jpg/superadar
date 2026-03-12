from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from playwright.async_api import Page


@dataclass(frozen=True)
class CapturaResultado:
    preco_detectado: float
    local_screenshot: Path


async def configurar_endereco(page: Page, endereco_loja: str) -> None:
    await page.goto("https://www.ifood.com.br/", wait_until="domcontentloaded")
    await page.click("button:has-text('Endereço')", timeout=15000)
    await page.fill("input[placeholder*='rua']", endereco_loja)
    await page.click(".address-search__item", timeout=15000)


async def capturar_preco_produto(
    page: Page,
    url_concorrente: str,
    termo_busca: str,
    ean_produto: str,
    print_dir: Path,
) -> CapturaResultado:
    await page.goto(url_concorrente, wait_until="domcontentloaded")
    await page.fill("input[placeholder*='Busque']", termo_busca)
    await page.keyboard.press("Enter")
    await page.wait_for_timeout(3000)

    preco_raw = await page.inner_text(".product-card__price")
    preco_float = float(preco_raw.replace("R$", "").replace(".", "").replace(",", ".").strip())

    print_dir.mkdir(parents=True, exist_ok=True)
    screenshot_path = print_dir / f"{ean_produto}_{datetime.now().strftime('%Y%m%d%H%M%S')}.png"
    await page.locator(".product-card").first.screenshot(path=str(screenshot_path))

    return CapturaResultado(preco_detectado=preco_float, local_screenshot=screenshot_path)
