from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    supabase_url: str
    supabase_key: str
    telegram_token: str
    telegram_chat_id: str
    endereco_loja: str = "R. Marinho Falcão, 55 - Vila Madalena, São Paulo"


    @classmethod
    def from_env(cls) -> "Settings":
        required_keys = [
            "SUPABASE_URL",
            "SUPABASE_KEY",
            "TELEGRAM_TOKEN",
            "TELEGRAM_CHAT_ID",
        ]
        missing = [key for key in required_keys if not os.getenv(key)]
        if missing:
            missing_list = ", ".join(missing)
            raise ValueError(f"Variáveis de ambiente obrigatórias ausentes: {missing_list}")

        return cls(
            supabase_url=os.environ["SUPABASE_URL"],
            supabase_key=os.environ["SUPABASE_KEY"],
            telegram_token=os.environ["TELEGRAM_TOKEN"],
            telegram_chat_id=os.environ["TELEGRAM_CHAT_ID"],
            endereco_loja=os.getenv(
                "ENDERECO_LOJA", "R. Marinho Falcão, 55 - Vila Madalena, São Paulo"
            ),
        )
