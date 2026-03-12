"""Vercel Python entrypoint (WSGI).

Exposes a lightweight HTTP app so Vercel can deploy this repository without
requiring a framework dependency.
"""

from __future__ import annotations

import json
from typing import Iterable


def _json_response(start_response, status: str, payload: dict) -> Iterable[bytes]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    headers = [
        ("Content-Type", "application/json; charset=utf-8"),
        ("Content-Length", str(len(body))),
    ]
    start_response(status, headers)
    return [body]


def app(environ, start_response):
    """WSGI callable expected by Vercel Python runtime."""
    method = environ.get("REQUEST_METHOD", "GET")
    path = environ.get("PATH_INFO", "/")

    if method == "GET" and path in {"/", "/health", "/api/health"}:
        return _json_response(
            start_response,
            "200 OK",
            {
                "service": "superadar-backend",
                "status": "ok",
                "message": "Vercel entrypoint ativo.",
            },
        )

    return _json_response(
        start_response,
        "404 Not Found",
        {"error": "not_found", "path": path, "method": method},
    )
