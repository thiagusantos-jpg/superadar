from __future__ import annotations

from pathlib import Path

import requests


class TelegramService:
    def __init__(self, token: str, chat_id: str) -> None:
        self.token = token
        self.chat_id = chat_id

    def send_message(self, message: str) -> None:
        url = f"https://api.telegram.org/bot{self.token}/sendMessage"
        response = requests.post(
            url,
            data={"chat_id": self.chat_id, "text": message, "parse_mode": "Markdown"},
            timeout=30,
        )
        response.raise_for_status()

    def send_photo(self, photo_path: Path, caption: str | None = None) -> None:
        url = f"https://api.telegram.org/bot{self.token}/sendPhoto"
        with photo_path.open("rb") as photo:
            response = requests.post(
                url,
                data={"chat_id": self.chat_id, "caption": caption},
                files={"photo": photo},
                timeout=60,
            )
            response.raise_for_status()
