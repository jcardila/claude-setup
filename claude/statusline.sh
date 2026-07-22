#!/bin/bash
# Claude Code statusline — Catppuccin Mocha (truecolor ANSI)
# Recibe JSON de sesión por stdin. Diseñado para funcionar bien en tmux.
#
# Toggle: export CLAUDE_STATUSLINE_ASCII=1  -> usa glyphs 100% ASCII (#/-, ^/v)
#         si tu fuente de terminal no renderiza █ / flechas y ves "???".
input=$(cat)

USE_ASCII="${CLAUDE_STATUSLINE_ASCII:-0}"

# ---------- Extracción de campos (UNA sola llamada a jq) ----------
# Cada spawn de jq cuesta ~8ms; agrupamos los 13 campos en un solo proceso.
# Separador = \x1f (unit separator, NO-whitespace): `read` NUNCA colapsa campos
# vacíos con él (con \t sí, porque el tab cuenta como whitespace para read =>
# los rate_limits ausentes corrían todos los campos hacia la izquierda).
# null -> "" (rate_limits ausentes salen vacíos sin desalinear el resto).
IFS=$'\x1f' read -r MODEL DIR PROJ PCT TOKENS WSIZE EXCEEDS R5 R7 ADDED REMOVED COST TRANSCRIPT < <(
  echo "$input" | jq -r '[
    .model.display_name // "—",
    .workspace.current_dir // "~",
    (.workspace.project_dir // .workspace.current_dir // ""),
    ((.context_window.used_percentage // 0) | floor),
    (.context_window.total_input_tokens // 0),
    (.context_window.context_window_size // 200000),
    (.exceeds_200k_tokens // false),
    (.rate_limits.five_hour.used_percentage | if . == null then null else floor end),
    (.rate_limits.seven_day.used_percentage | if . == null then null else floor end),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.cost.total_cost_usd // 0),
    (.transcript_path // "")
  ] | map(if . == null then "" else tostring end) | join("")'
)

# ---------- Colores (Catppuccin Mocha, truecolor) ----------
LAVENDER='\033[38;2;180;190;254m'
MAUVE='\033[38;2;203;166;247m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
PEACH='\033[38;2;250;179;135m'
SKY='\033[38;2;137;220;235m'
TEAL='\033[38;2;148;226;213m'
BLUE='\033[38;2;137;180;250m'
SURFACE1='\033[38;2;69;71;90m'
DIM='\033[2m'
RESET='\033[0m'
SEP="${SURFACE1}│${RESET}"

# ---------- Glyphs de git (flechas ahead/behind; con fallback ASCII) ----------
# NOTA: los literales multibyte (↑ ↓ │) se imprimen bien vía echo -e.
# El problema son SOLO los construidos con `tr` (ver la barra abajo).
if [ "$USE_ASCII" = "1" ]; then
  A_UP='^'; A_DN='v'
else
  A_UP='↑'; A_DN='↓'
fi

# ---------- Indicador tmux (heredado del entorno de Claude Code) ----------
# $TMUX está presente si la sesión se lanzó dentro de tmux. Confirmación tenue
# cuando SÍ; alarma con fondo rojo cuando NO (para no olvidar arrancar tmux).
if [ -n "$TMUX" ]; then
  TMUX_BADGE="${GREEN}tmux${RESET}"
else
  TMUX_BADGE="\033[48;2;243;139;168m\033[38;2;30;30;46m NO-TMUX ${RESET}"
fi

# ---------- Effort level (no viene en el JSON del statusline) ----------
# FUENTE PRIMARIA: el transcript de ESTA sesión. Registra cada "/effort",
# incluido el modo session-only 'ultracode' que NO se persiste en settings.json.
# Anclamos en el wrapper <local-command-stdout> para NO confundir con texto del
# assistant (que guarda content como array, no como string con ese prefijo).
# `tac` lee desde el final => el primer match es el effort ACTUAL.
# FALLBACK: settings.json (el default con el que arrancó la sesión), respetando
# la precedencia de Claude Code (proyecto local > proyecto > usuario).
EFFORT=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Filtro por ESTRUCTURA (no solo texto): solo mensajes type=user cuyo content
  # sea STRING y salga del comando /effort. Los mensajes del assistant tienen
  # content=array => se descartan (evita que mi propia prosa citando el wrapper
  # sea confundida con la salida real del comando). El último match = el actual.
  EFFORT=$(jq -r 'select(.type=="user" and (.message.content? | type=="string")
                         and (.message.content | test("<local-command-stdout>Set effort level to")))
                  | .message.content' "$TRANSCRIPT" 2>/dev/null \
           | grep -oE 'Set effort level to [a-zA-Z]+' | tail -1 | sed 's/.* //')
fi
if [ -z "$EFFORT" ]; then
  for f in "$PROJ/.claude/settings.local.json" "$PROJ/.claude/settings.json" "$HOME/.claude/settings.json"; do
    [ -z "$EFFORT" ] && [ -f "$f" ] && EFFORT=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
  done
fi
case "$EFFORT" in
  low)        EFFORT_COLOR="$GREEN" ;;
  medium)     EFFORT_COLOR="$SKY" ;;
  high)       EFFORT_COLOR="$PEACH" ;;
  xhigh|max)  EFFORT_COLOR="$RED" ;;
  ultracode)  EFFORT_COLOR="$MAUVE" ;;
  *)          EFFORT_COLOR="$DIM" ;;
esac

# ---------- Usuario de Claude (LECTURA EN VIVO; /login lo cambia a mitad de sesión) ----------
# .claude.json pesa ~43K y jq tarda ~6ms => se lee en cada render, sin cache,
# para garantizar que refleje la cuenta ACTUAL tras un /login.
ACCOUNT=$(jq -r '.oauthAccount.emailAddress // .oauthAccount.displayName // ""' "$HOME/.claude.json" 2>/dev/null)

# ---------- Directorio abreviado ----------
DIR=$(echo "$DIR" | sed "s|^$HOME|~|; s|/var/www/magento2|M2|")

# ---------- Humanizar tokens (142000 -> 142k, 1000000 -> 1.0M) ----------
fmt_tokens() {
  local n=$1
  if   [ "$n" -ge 1000000 ]; then printf "%d.%dM" $((n/1000000)) $(((n%1000000)/100000))
  elif [ "$n" -ge 1000 ];    then printf "%dk" $((n/1000))
  else printf "%d" "$n"; fi
}
TOK_H=$(fmt_tokens "$TOKENS")
WSIZE_H=$(fmt_tokens "$WSIZE")

# ---------- Barra de contexto (bloques por color de FONDO; sin glyphs Unicode) ----------
# Umbral de color. BAR_FG se usa solo en modo ASCII; BAR_BG es el fondo del bloque.
if   [ "$PCT" -ge 90 ];       then BAR_FG="$RED";    BAR_BG='\033[48;2;243;139;168m'
elif [ "$PCT" -ge 70 ];       then BAR_FG="$YELLOW"; BAR_BG='\033[48;2;249;226;175m'
elif [ "$EXCEEDS" = "true" ]; then BAR_FG="$PEACH";  BAR_BG='\033[48;2;250;179;135m'  # cruzó 200k (modelo 1M)
else                               BAR_FG="$GREEN";  BAR_BG='\033[48;2;166;227;161m'; fi
BG_SURF='\033[48;2;69;71;90m'

BAR_WIDTH=16
FILLED=$((PCT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
[ "$FILLED" -lt 0 ] && FILLED=0
EMPTY=$((BAR_WIDTH - FILLED))
if [ "$USE_ASCII" = "1" ]; then
  # ASCII: tr es SEGURO con caracteres de 1 byte (#, -).
  FILL_STR=$(printf "%${FILLED}s" '' | tr ' ' '#')
  EMPTY_STR=$(printf "%${EMPTY}s" '' | tr ' ' '-')
  BAR="${BAR_FG}${FILL_STR}${SURFACE1}${EMPTY_STR}${RESET}"
else
  # Bloques = espacios con color de fondo. No dependen de ninguna fuente Unicode.
  # (El bug original: `tr ' ' '█'` parte el UTF-8 de 3 bytes en bytes sueltos -> "???".)
  FILL_SP=$(printf "%${FILLED}s" '')
  EMPTY_SP=$(printf "%${EMPTY}s" '')
  BAR="${BAR_BG}${FILL_SP}${BG_SURF}${EMPTY_SP}${RESET}"
fi

# Etiqueta de tokens: peach si cruzó 200k
TOK_COLOR="$LAVENDER"; TOK_TAG=""
if [ "$EXCEEDS" = "true" ]; then TOK_COLOR="$PEACH"; TOK_TAG=" ${PEACH}200k+${RESET}"; fi

# ---------- Git (cache POR DIRECTORIO para no pisarse entre panes de tmux) ----------
DIR_HASH=$(printf '%s' "$PROJ" | cksum | cut -d' ' -f1)
CACHE_FILE="/tmp/claude-statusline-git-${DIR_HASH}"
CACHE_MAX_AGE=5
NEED_REFRESH=1
if [ -f "$CACHE_FILE" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
  [ "$AGE" -le "$CACHE_MAX_AGE" ] && NEED_REFRESH=0
fi
if [ "$NEED_REFRESH" -eq 1 ]; then
  if [ -n "$PROJ" ] && git -C "$PROJ" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$PROJ" branch --show-current 2>/dev/null)
    STAGED=$(git -C "$PROJ" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$PROJ" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$PROJ" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    AB=$(git -C "$PROJ" rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
    BEHIND=$(echo "$AB" | cut -f1); AHEAD=$(echo "$AB" | cut -f2)
    [ -z "$AHEAD" ] && AHEAD=0; [ -z "$BEHIND" ] && BEHIND=0
    echo "$BRANCH|$STAGED|$MODIFIED|$UNTRACKED|$AHEAD|$BEHIND" > "$CACHE_FILE"
  else
    echo "|||||" > "$CACHE_FILE"
  fi
fi
IFS='|' read -r BRANCH STAGED MODIFIED UNTRACKED AHEAD BEHIND < "$CACHE_FILE"

# ---------- LÍNEA 1: [tmux] | modelo · effort | usuario | dir | git ----------
LINE1="${TMUX_BADGE} ${SEP} ${MAUVE}${MODEL}${RESET}"
[ -n "$EFFORT" ] && LINE1="${LINE1} ${DIM}·${RESET} ${EFFORT_COLOR}${EFFORT}${RESET}"
[ -n "$ACCOUNT" ] && LINE1="${LINE1} ${SEP} ${DIM}${ACCOUNT}${RESET}"
LINE1="${LINE1} ${SEP} ${SKY}${DIR}${RESET}"
if [ -n "$BRANCH" ]; then
  GIT_EXTRA=""
  [ "${STAGED:-0}" -gt 0 ]    && GIT_EXTRA="${GIT_EXTRA} ${GREEN}+${STAGED}${RESET}"
  [ "${MODIFIED:-0}" -gt 0 ]  && GIT_EXTRA="${GIT_EXTRA} ${PEACH}~${MODIFIED}${RESET}"
  [ "${UNTRACKED:-0}" -gt 0 ] && GIT_EXTRA="${GIT_EXTRA} ${BLUE}?${UNTRACKED}${RESET}"
  [ "${AHEAD:-0}" -gt 0 ]     && GIT_EXTRA="${GIT_EXTRA} ${GREEN}${A_UP}${AHEAD}${RESET}"
  [ "${BEHIND:-0}" -gt 0 ]    && GIT_EXTRA="${GIT_EXTRA} ${RED}${A_DN}${BEHIND}${RESET}"
  LINE1="${LINE1} ${SEP} ${TEAL}${BRANCH}${RESET}${GIT_EXTRA}"
fi

# ---------- LÍNEA 2: barra tokens % | límites 5h/7d | líneas | costo ----------
LINE2="${BAR} ${TOK_COLOR}${TOK_H}${RESET}${DIM}/${WSIZE_H}${RESET} ${LAVENDER}${PCT}%${RESET}${TOK_TAG}"

# Límites de tasa (solo si el JSON los trae — suscriptores Pro/Max)
rl_color() { # $1 = pct
  if   [ "$1" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}
RL=""
[ -n "$R5" ] && RL="${RL} ${DIM}5h${RESET} $(rl_color "$R5")${R5}%${RESET}"
[ -n "$R7" ] && RL="${RL} ${DIM}7d${RESET} $(rl_color "$R7")${R7}%${RESET}"
[ -n "$RL" ] && LINE2="${LINE2} ${SEP}${RL}"

# Líneas cambiadas
if [ "${ADDED:-0}" -gt 0 ] || [ "${REMOVED:-0}" -gt 0 ]; then
  LINE2="${LINE2} ${SEP} ${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
fi

# Costo estimado (dim)
# LC_NUMERIC=C: en locales con coma decimal (es_CO, es_ES...) printf rechaza "0.42"
# como número inválido y la statusline mostraba basura tipo "$0,000.00".
COST_FMT=$(LC_NUMERIC=C printf '%.2f' "$COST" 2>/dev/null || echo "0.00")
[ "$COST_FMT" != "0.00" ] && LINE2="${LINE2} ${SEP} ${DIM}\$${COST_FMT}${RESET}"

echo -e "$LINE1"
echo -e "$LINE2"
