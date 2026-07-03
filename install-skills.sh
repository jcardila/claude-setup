#!/usr/bin/env bash
# Instala mis skills de Claude en un proyecto concreto (por-proyecto).
# Uso:  ./install-skills.sh /ruta/al/proyecto
# Sin argumento usa el directorio actual.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$PWD}"

if [ ! -d "$TARGET" ]; then
  echo "No existe el directorio: $TARGET" >&2; exit 1
fi

DEST="$TARGET/.claude/skills"
mkdir -p "$DEST"
cp -r "$REPO_DIR"/claude/skills/* "$DEST/"
chmod +x "$DEST"/*/*.sh 2>/dev/null || true

echo "Skills instaladas en $DEST:"
ls -1 "$DEST"
