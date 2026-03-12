from __future__ import annotations

from pathlib import Path
from typing import Any

from supabase import Client, create_client


class SupabaseService:
    def __init__(self, url: str, key: str) -> None:
        self.client: Client = create_client(url, key)

    def upload_print(
        self,
        bucket: str,
        local_file_path: Path,
        remote_path: str,
        *,
        upsert: bool = True,
    ) -> str:
        with local_file_path.open("rb") as file_handle:
            self.client.storage.from_(bucket).upload(
                path=remote_path,
                file=file_handle,
                file_options={"content-type": "image/png", "upsert": str(upsert).lower()},
            )

        return self.client.storage.from_(bucket).get_public_url(remote_path)

    def insert_historico_mercado(
        self,
        ean: str,
        preco_detectado: float,
        url_print: str,
        concorrente_id: str | None = None,
    ) -> Any:
        payload: dict[str, Any] = {
            "ean": ean,
            "preco_detectado": preco_detectado,
            "url_print": url_print,
            "concorrente_id": concorrente_id,
        }
        return self.client.table("historico_mercado").insert(payload).execute()
