#!/usr/bin/env bash
set -euo pipefail

# Sincroniza a branch atual com a branch base e resolve automaticamente
# conflitos conhecidos do PR mantendo a versão da branch atual (--ours).
#
# Uso:
#   ./scripts/sync_and_resolve_conflicts.sh [remote] [base_branch]
# Exemplo:
#   ./scripts/sync_and_resolve_conflicts.sh origin main

REMOTE_NAME="${1:-origin}"
BASE_BRANCH="${2:-main}"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

KNOWN_CONFLICT_FILES=(
  ".github/workflows/main.yml"
  "README.md"
  "backend/app/config.py"
  "backend/app/main.py"
  "backend/app/services/supabase_service.py"
  "supabase/README.md"
)

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Erro: execute dentro de um repositório git." >&2
  exit 1
fi

if ! git remote | grep -qx "$REMOTE_NAME"; then
  echo "Erro: remote '$REMOTE_NAME' não existe. Configure com:" >&2
  echo "  git remote add $REMOTE_NAME <url-do-repositorio>" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Erro: working tree não está limpa. Faça commit/stash antes de rodar." >&2
  exit 1
fi

echo "[1/4] Fetch de $REMOTE_NAME/$BASE_BRANCH"
git fetch "$REMOTE_NAME" "$BASE_BRANCH"

echo "[2/4] Merge de $REMOTE_NAME/$BASE_BRANCH em $CURRENT_BRANCH"
set +e
git merge --no-ff --no-commit "$REMOTE_NAME/$BASE_BRANCH"
merge_exit=$?
set -e

if [ "$merge_exit" -ne 0 ]; then
  echo "Merge com conflitos detectado. Tentando resolução automática dos arquivos conhecidos..."
fi

for file in "${KNOWN_CONFLICT_FILES[@]}"; do
  if [ -n "$(git ls-files -u -- "$file")" ]; then
    echo "[resolve] $file -> mantendo versão da branch atual (--ours)"
    git checkout --ours -- "$file"
    git add "$file"
  fi
done

if [ -n "$(git ls-files -u)" ]; then
  echo "Erro: ainda existem conflitos não resolvidos automaticamente:" >&2
  git diff --name-only --diff-filter=U >&2
  echo "Resolva manualmente, rode git add e finalize com git commit." >&2
  exit 1
fi

echo "[3/4] Criando commit de merge"
git commit -m "chore: merge $REMOTE_NAME/$BASE_BRANCH and resolve known PR conflicts"

echo "[4/4] Concluído. Faça push para atualizar o PR:"
echo "  git push $REMOTE_NAME $CURRENT_BRANCH"
