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


## Deploy na Vercel
Para evitar erro de entrypoint, o projeto inclui `main.py` (WSGI) na raiz.
Após o deploy, teste `GET /health` para validar que o runtime Python subiu corretamente.


## Resolver conflitos de merge no PR
Se o GitHub mostrar conflitos com `main`, rode o script automatizado:
```bash
./scripts/sync_and_resolve_conflicts.sh origin main
```
Ele faz `fetch`, `merge`, resolve automaticamente os conflitos conhecidos do PR
mantendo sua versão nos arquivos listados e cria o commit de merge.

Se aparecerem conflitos fora da lista, o script para e mostra quais arquivos
precisam de resolução manual.


## Frontend (Dashboard)
O dashboard está em `index.html` e segue o PRD (Tailwind + HTML puro + modal de prova visual + PDF).

### Configuração rápida
1. Abra `index.html`.
2. No bloco `window.SUPERADAR_CONFIG`, informe:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` (publishable key)
3. Publique na Vercel como projeto estático.

### Observações de segurança
- **Nunca** use `service_role key` no frontend.
- O frontend deve usar apenas chave publishable/anon.
