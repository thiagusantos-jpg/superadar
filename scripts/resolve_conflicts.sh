#!/usr/bin/env bash
set -euo pipefail

# Uso:
# 1) git fetch origin
# 2) git merge origin/main
# 3) ./scripts/resolve_conflicts.sh

FILES=(
  ".github/workflows/main.yml"
  "README.md"
  "backend/app/config.py"
  "backend/app/main.py"
  "backend/app/services/supabase_service.py"
  "supabase/README.md"
)

for file in "${FILES[@]}"; do
  if git ls-files -u -- "$file" >/dev/null 2>&1 && [ -n "$(git ls-files -u -- "$file")" ]; then
    echo "[resolve] mantendo versão da branch atual para: $file"
    git checkout --ours -- "$file"
    git add "$file"
  fi
done

if [ -n "$(git ls-files -u)" ]; then
  echo "Ainda há conflitos pendentes em outros arquivos. Resolva manualmente e rode git add." >&2
  git status --short
  exit 1
fi

echo "Conflitos listados resolvidos. Revise diff e finalize com:"
echo "git commit -m 'chore: resolve merge conflicts with main'"
