# SuperRadar Backend (v1)

Implementação inicial do backend serverless descrito no `PRD_SUPERADAR_V1.md`.

## Estrutura
- `backend/app/main.py`: orquestra captura, upload e persistência.
- `backend/app/services/ifood_scraper.py`: automação Playwright.
- `backend/app/services/supabase_service.py`: Storage + inserts no banco.
- `backend/app/services/telegram_service.py`: alertas no Telegram.
- `supabase/migrations/`: schema + trigger + RLS + bucket/policies.
- `.github/workflows/main.yml`: execução diária 06:30 BRT.

## Setup local
1. Crie e ative um virtualenv.
2. Instale dependências:
   ```bash
   pip install -r requirements.txt
   playwright install chromium
   ```
3. Copie `.env.example` para `.env` e preencha os valores.
4. Exporte variáveis e execute:
   ```bash
   python -m backend.app.main
   ```

## Supabase
Siga `supabase/README.md` para aplicar migration e seed.
