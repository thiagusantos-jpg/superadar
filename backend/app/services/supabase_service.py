from supabase import create_client
from config import SUPABASE_URL, SUPABASE_KEY
from typing import Dict, Any
import os

class SupabaseService:
    def __init__(self):
        self.client = create_client(SUPABASE_URL, SUPABASE_KEY)

    def inserir_historico_mercado(self, ean: str, preco_detectado: float,
                                   url_print: str, concorrente_id: str = None) -> Dict[str, Any]:
        """Inserir registro de preço capturado no histórico"""
        data = {
            "ean": ean,
            "preco_detectado": preco_detectado,
            "url_print": url_print
        }
        if concorrente_id:
            data["concorrente_id"] = concorrente_id

        response = self.client.table("historico_mercado").insert(data).execute()
        return response.data[0] if response.data else None

    def obter_fila_pendentes(self) -> list:
        """Obter todos os preços pendentes de aprovação"""
        response = self.client.table("fila_precos_pendentes").select(
            "*"
        ).eq("status", "pendente").execute()
        return response.data or []

    def obter_produto_by_ean(self, ean: str) -> Dict[str, Any]:
        """Obter dados do produto pelo EAN"""
        response = self.client.table("produtos").select(
            "*"
        ).eq("ean", ean).execute()
        return response.data[0] if response.data else None

    def upload_print(self, file_path: str, bucket_name: str = "prints_concorrentes") -> str:
        """Upload de screenshot para Storage"""
        with open(file_path, 'rb') as f:
            self.client.storage.from_(bucket_name).upload(
                path=file_path,
                file=f,
                file_options={"content-type": "image/png"}
            )

        url_publica = self.client.storage.from_(bucket_name).get_public_url(file_path)
        return url_publica

    def obter_produto_preco_atual(self, ean: str) -> float:
        """Obter preço atual de venda do produto"""
        produto = self.obter_produto_by_ean(ean)
        return produto["preco_venda_atual"] if produto else None
