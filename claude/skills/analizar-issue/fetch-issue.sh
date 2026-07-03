#!/usr/bin/env bash
# fetch-issue.sh — Trae un issue de GitHub con TODOS sus comentarios y
# descarga sus imágenes adjuntas (autenticadas) para poder analizarlas.
#
# Uso:   ./fetch-issue.sh <numero> [numero...]
# Salida: texto formateado a stdout + imágenes descargadas en /tmp/gh-issue-<n>/
#
# Solo-lectura: NO modifica el issue. La auto-asignación es un paso aparte
# documentado en SKILL.md.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: 'gh' no está instalado." >&2; exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: 'gh' no está autenticado. Corre: gh auth login" >&2; exit 1
fi
if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <numero-issue> [numero-issue...]" >&2; exit 1
fi

TOKEN="$(gh auth token)"

# Extrae URLs de imágenes de un texto (cubre <img src="...">, ![](...),
# user-attachments/assets/<uuid> sin extensión, y links directos .png/.jpg/...).
extract_urls() {
  grep -oE 'https://github\.com/user-attachments/assets/[A-Za-z0-9-]+|https://user-images\.githubusercontent\.com/[^ )"'"'"'<>]+|https://[^ )"'"'"'<>]+\.(png|jpe?g|gif|webp|bmp)' || true
}

# Mapea la salida de `file` a una extensión.
ext_for() {
  case "$(file -b "$1")" in
    PNG*)  echo png ;;
    JPEG*) echo jpg ;;
    GIF*)  echo gif ;;
    *WebP*|*WEBP*) echo webp ;;
    *) echo bin ;;
  esac
}

for NUM in "$@"; do
  OUTDIR="/tmp/gh-issue-${NUM}"
  rm -rf "$OUTDIR"; mkdir -p "$OUTDIR"
  JSON="$OUTDIR/issue.json"

  gh issue view "$NUM" \
    --json number,title,state,author,labels,assignees,milestone,createdAt,updatedAt,url,body,comments \
    > "$JSON"

  echo "============================================================"
  echo "ISSUE #$(jq -r .number "$JSON") — $(jq -r .title "$JSON")"
  echo "============================================================"
  echo "Estado:     $(jq -r .state "$JSON")"
  echo "Autor:      $(jq -r .author.login "$JSON")"
  echo "Creado:     $(jq -r .createdAt "$JSON")"
  echo "Actualizado:$(jq -r .updatedAt "$JSON")"
  echo "Labels:     $(jq -r '[.labels[].name] | join(", ") // "—"' "$JSON")"
  echo "Asignados:  $(jq -r 'if (.assignees|length)>0 then [.assignees[].login]|join(", ") else "(ninguno)" end' "$JSON")"
  echo "Milestone:  $(jq -r '.milestone.title // "—"' "$JSON")"
  echo "URL:        $(jq -r .url "$JSON")"
  echo
  echo "----- DESCRIPCIÓN -----"
  jq -r .body "$JSON"
  echo

  NC=$(jq -r '.comments | length' "$JSON")
  echo "----- COMENTARIOS ($NC) -----"
  if [ "$NC" -gt 0 ]; then
    jq -r '.comments[] | "\n[@\(.author.login) — \(.createdAt)]\n\(.body)"' "$JSON"
  else
    echo "(sin comentarios)"
  fi
  echo

  # Reúne body + todos los comentarios y extrae URLs de imágenes.
  URLS=$(jq -r '.body, (.comments[].body // empty)' "$JSON" | extract_urls | sort -u)
  echo "----- IMÁGENES -----"
  if [ -z "$URLS" ]; then
    echo "(sin imágenes adjuntas)"
  else
    i=0
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      i=$((i+1))
      TMP="$OUTDIR/img-${i}.download"
      code=$(curl -sL -H "Authorization: token $TOKEN" -o "$TMP" -w '%{http_code}' "$url")
      if [ "$code" != "200" ]; then
        echo "  [!] img-$i: HTTP $code — no se pudo descargar: $url"
        rm -f "$TMP"; continue
      fi
      EXT=$(ext_for "$TMP")
      FINAL="$OUTDIR/img-${i}.${EXT}"
      mv "$TMP" "$FINAL"
      echo "  img-$i: $FINAL  ($(file -b "$FINAL" | cut -d, -f1,2))"
      echo "          origen: $url"
    done <<< "$URLS"
    echo
    echo ">> Lee cada ruta de arriba con la herramienta Read para analizar las imágenes."
  fi
  echo
done
