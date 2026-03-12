# SuperRadar Backend (v1)

Implementação inicial do backend serverless descrito no `PRD_SUPERADAR_V1.md`.

## Estrutura
- `backend/app/main.py`: orquestra captura, upload e persistência.
- `backend/app/services/ifood_scraper.py`: automação Playwright.
- `backend/app/services/supabase_service.py`: Storage + inserts no banco.
- `backend/app/services/telegram_service.py`: alertas no Telegram.
- `supabase/migrations/`: schema + trigger + RLS + bucket/policies.
- `.github/workflows/main.yml`: execução diária 06:30 BRT + checklist de secrets.

## Setup local
1. Crie e ative um virtualenv.
2. Instale dependências:
   ```bash
   pip install -r requirements.txt
   playwright install chromium
   ```
3. Configure variáveis de ambiente.
4. Exporte variáveis e execute:
   ```bash
   python app.py
   # ou: python -m backend.app.main
   ```

## Supabase keys (segurança)
- **`SUPABASE_ANON_KEY`**: chave pública para clientes frontend. Respeita RLS e deve ser tratada como chave de baixo privilégio.
- **`SUPABASE_SERVICE_ROLE_KEY`**: chave **privilegiada** para backend/automação (robô), usada para escrita em tabelas operacionais e upload no Storage.

> 🚫 **Nunca use `service_role key` no frontend** (web/mobile). Ela deve ficar somente em ambiente servidor (GitHub Actions secrets, backend e funções privadas).

Neste projeto, o robô usa exclusivamente `SUPABASE_SERVICE_ROLE_KEY` via variável de ambiente no backend e no workflow.

## Uploads de prints
- Caminho remoto padronizado: `prints/<ean>_<timestamp>.png`.
- Metadados definidos no upload: `content-type: image/png`.

## GitHub Actions: checklist de segurança de secrets
Antes de executar o scraper, o workflow valida:
- Presença de secrets obrigatórios (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TELEGRAM_TOKEN`, `TELEGRAM_CHAT_ID`, `ENDERECO_LOJA`, `SCAN_TARGETS_JSON`).
- Rejeição de configuração inválida onde a `SUPABASE_SERVICE_ROLE_KEY` aparenta ser uma `anon key`.

## Supabase
Siga `supabase/README.md` para aplicar migrations e seed.
