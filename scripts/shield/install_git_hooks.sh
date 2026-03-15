#!/usr/bin/env bash
# Git hooks kurar: post-merge (pull sonrası shield), pre-commit (hafif).
# Proje kökünde .git varsa hooks dizinine kopyalar.
set -e
source "$(dirname "$0")/config.sh"
HOOKS_SRC="$SHIELD_DIR/hooks"
GIT_DIR="$PROJECT_ROOT/.git"
if [[ ! -d "$GIT_DIR" ]]; then
  echo "shield: .git yok, git hooks atlanıyor."
  exit 0
fi
for name in post-merge pre-commit; do
  src="$HOOKS_SRC/${name}.sample"
  dst="$GIT_DIR/hooks/$name"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "shield: hook kuruldu — $name"
  fi
done
echo "shield: Git hooks kurulumu bitti."
exit 0
