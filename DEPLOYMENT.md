# 🚀 SuperRadar - Guia de Deployment

## Status Atual
✅ Repositório local inicializado
✅ Commit inicial realizado (77fb72a)
⏳ Aguardando push para GitHub

---

## Passo 1: Configurar Remote do GitHub

### Opção A: Já tem repositório no GitHub

```bash
cd /Users/thiago/Documents/apps_code/superadar

# Adicione seu repositório (substitua USUARIO/REPO)
git remote add origin https://github.com/USUARIO/superadar.git

# Se está em master, rename para main (padrão GitHub)
git branch -M main

# Push inicial
git push -u origin main
```

### Opção B: Criar novo repositório no GitHub

1. Acesse https://github.com/new
2. Crie `superadar` (não inicialize README)
3. Execute:

```bash
git remote add origin https://github.com/SEU_USUARIO/superadar.git
git branch -M main
git push -u origin main
```

---

## Passo 2: Resolver PR com Conflitos (se existir)

Se você tem um PR aberto com conflitos:

### Opção A: Rebase (Recomendado - Histórico Linear)

```bash
# Buscar última versão
git fetch origin

# Rebase no main remoto
git rebase origin/main

# Se houver conflitos, resolva-os, depois:
git add .
git rebase --continue

# Force push (apenas em branches de feature, nunca em main)
git push origin main --force
```

### Opção B: Merge (Simples - Mantém Histórico)

```bash
# Buscar última versão
git fetch origin

# Merge main remoto
git merge origin/main

# Se houver conflitos, resolva-os, depois:
git add .
git commit -m "Merge: Resolver conflitos"

# Push normal
git push origin main
```

---

## Passo 3: Verificar Status

```bash
# Ver branches
git branch -a

# Ver remotes
git remote -v

# Ver logs
git log --oneline --graph --all
```

---

## Estrutura Final para GitHub

Após fazer push, seu repositório terá:

```
superadar/
├── main branch (seu código)
├── GitHub Pages (opcional, para frontend)
├── Secrets configurados (SUPABASE_URL, etc)
└── Actions habilitadas
```

---

## Configuração GitHub (após push)

### 1. Habilitar GitHub Actions
```
Settings > Actions > General
✓ Allow all actions and reusable workflows
```

### 2. Adicionar Secrets
```
Settings > Secrets and variables > Actions > New repository secret

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
TELEGRAM_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
```

### 3. Verificar Actions
```
Actions > SuperRadar Daily Scan
✓ Deve mostrar schedule: 30 9 * * * (06:30 BRT)
```

### 4. Deploy Frontend (opcional)
```
Settings > Pages > Source: Deploy from a branch
Branch: main
Folder: /frontend
```

---

## Comandos Úteis

```bash
# Ver status detalhado
git status

# Ver mudanças não commitadas
git diff

# Ver histórico
git log --oneline -10

# Desfazer último commit (mantém arquivos)
git reset --soft HEAD~1

# Desfazer último commit (descarta arquivos)
git reset --hard HEAD~1

# Criar nova branch
git checkout -b feature/nome-da-feature

# Mudar de branch
git checkout main

# Fazer push de uma branch específica
git push origin feature/nome-da-feature
```

---

## Troubleshooting

### "fatal: not a git repository"
```bash
cd /Users/thiago/Documents/apps_code/superadar
# Já está inicializado, execute git init se necessário
```

### "remote: Permission denied"
- Verificar autenticação GitHub (token ou SSH)
- Usar: `git config user.name` e `git config user.email`

### "Conflitos ao fazer merge"
```bash
# Ver conflitos
git status

# Editar arquivo .rej (onde estão os conflitos)
# Depois:
git add arquivo-resolvido
git merge --continue
```

### "Histórico local diferente do remoto"
```bash
# Force pull (cuidado!)
git fetch origin
git reset --hard origin/main

# Ou rebase
git rebase origin/main
```

---

## CI/CD Pipeline (após setup)

### Trigger automático
1. ✅ Daily: 06:30 BRT (cron)
2. ✅ Manual: Actions > Run workflow
3. ✅ On push: quando fizer push

### O que acontece
```
GitHub Actions
    ↓
python -m app.main
    ↓
Captura iFood via Playwright
    ↓
Upload Supabase Storage
    ↓
Insert historico_mercado (ativa trigger)
    ↓
Alerta Telegram
```

---

## Monitoramento

### Ver logs da última execução
```
GitHub > Actions > SuperRadar Daily Scan > clique na execução
```

### Ver alertas no Telegram
Você receberá mensagens automáticas no grupo configurado em `TELEGRAM_CHAT_ID`

### Ver dados no Supabase
```
https://app.supabase.com/project/[seu-projeto]/editor/0
```

---

## Próximas Fases

- [ ] Fase 3: Frontend interativo com API
- [ ] Fase 4: Autenticação e RBAC
- [ ] Fase 5: Mobile App (React Native)

---

**Pronto para fazer push?** Execute:

```bash
cd /Users/thiago/Documents/apps_code/superadar
git remote add origin https://github.com/SEU_USUARIO/superadar.git
git branch -M main
git push -u origin main
```

Depois configure os Secrets no GitHub e o sistema estará 100% operacional! 🚀
