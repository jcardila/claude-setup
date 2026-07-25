#!/usr/bin/env bash
# Instala mi setup de tmux + Claude Code (statusline, hooks, prefs).
# Idempotente: se puede correr N veces sin romper nada.
# Las SKILLS son por-proyecto -> usar ./install-skills.sh <dir-proyecto>.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

info()  { printf '\033[38;2;166;227;161m[ok]\033[0m %s\n' "$1"; }
warn()  { printf '\033[38;2;249;226;175m[!]\033[0m %s\n' "$1"; }
step()  { printf '\n\033[38;2;180;190;254m== %s ==\033[0m\n' "$1"; }

# backup + symlink: respeta cualquier archivo previo moviéndolo a *.bak-<ts>
link() {
  local src="$1" dst="$2" ts
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    info "$dst ya enlazado"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    ts=$(date +%Y%m%d-%H%M%S)
    mv "$dst" "$dst.bak-$ts"
    warn "backup: $dst -> $dst.bak-$ts"
  fi
  ln -s "$src" "$dst"
  info "enlazado $dst"
}

# ---------------------------------------------------------------------------
step "Dependencias"
missing=()
for bin in tmux git jq sed; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ "${#missing[@]}" -gt 0 ]; then
  warn "faltan: ${missing[*]} — instala con: sudo apt install ${missing[*]}"
else
  info "tmux, git, jq, sed presentes"
fi

# ---------------------------------------------------------------------------
step "tmux"
link "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link "$REPO_DIR/tmux/scripts"   "$HOME/.tmux/scripts"

# TPM (gestor de plugins de tmux) — requerido por catppuccin
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR/.git" ]; then
  info "TPM ya instalado"
else
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  info "TPM clonado"
fi
warn "Dentro de tmux, presiona  Ctrl+b  luego  I  (mayúscula) para instalar catppuccin."

# ---------------------------------------------------------------------------
step "Claude Code"
link "$REPO_DIR/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
link "$REPO_DIR/claude/hooks"         "$CLAUDE_DIR/hooks"

# settings.json: mergear prefs portables SIN pisar permisos/credenciales locales
SETTINGS="$CLAUDE_DIR/settings.json"
PORTABLE="$REPO_DIR/claude/settings.portable.json"
mkdir -p "$CLAUDE_DIR"
if [ -f "$SETTINGS" ]; then
  ts=$(date +%Y%m%d-%H%M%S)
  cp "$SETTINGS" "$SETTINGS.bak-$ts"
  # los valores del repo tienen prioridad; el resto del settings local se conserva
  jq -s '.[0] * .[1]' "$SETTINGS" "$PORTABLE" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  info "settings.json mergeado (backup en $SETTINGS.bak-$ts)"
else
  cp "$PORTABLE" "$SETTINGS"
  info "settings.json creado"
fi

# ---------------------------------------------------------------------------
step "Remote Control + fallback por safeguards"

# lee una clave booleana sin que jq confunda `false` con "ausente" (`//` lo hace)
getbool() { jq -r --arg k "$2" 'if has($k) then (.[$k]|tostring) else "unset" end' "$1"; }

# 1) Remote Control automático en cada sesión (remoteControlAtStartup: true).
#    settings.json (userSettings) gana sobre el valor del /config (~/.claude.json),
#    PERO un settings.json de proyecto o un settings.local.json con
#    remoteControlAtStartup:false lo apagan igual. Avisamos si eso pasa aquí.
rc_val=$(getbool "$SETTINGS" remoteControlAtStartup)
[ "$rc_val" = "true" ] && info "remoteControlAtStartup=true (RC arranca solo en cada sesión)" \
                       || warn "remoteControlAtStartup=$rc_val — revisa $SETTINGS"

for f in "$CLAUDE_DIR/settings.local.json" "$PWD/.claude/settings.json" "$PWD/.claude/settings.local.json"; do
  if [ -f "$f" ] && [ "$(getbool "$f" remoteControlAtStartup)" = "false" ]; then
    warn "$f pone remoteControlAtStartup:false y ese scope tiene prioridad — quítalo"
  fi
done

# managed settings de la org: kill-switch que gana sobre todo
for f in /etc/claude-code/managed-settings.json "/Library/Application Support/ClaudeCode/managed-settings.json"; do
  if [ -f "$f" ] && [ "$(getbool "$f" disableRemoteControl)" = "true" ]; then
    warn "política de la org: disableRemoteControl:true en $f — Remote Control no podrá arrancar"
  fi
done

# 2) Nada de auto-cambio de modelo cuando los safeguards marcan un mensaje.
sm_val=$(getbool "$SETTINGS" switchModelsOnFlag)
[ "$sm_val" = "false" ] && info "switchModelsOnFlag=false (la sesión pausa y pregunta; no cambia de modelo sola)" \
                        || warn "switchModelsOnFlag=$sm_val — revisa $SETTINGS"

# ---------------------------------------------------------------------------
step "Plugin frontend-design (marketplace claude-plugins-official)"
PLUGIN="frontend-design@claude-plugins-official"
if command -v claude >/dev/null 2>&1; then
  # 1) marketplace (idempotente: si ya está, no falla)
  claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
  # 2) instalar a nivel usuario si aún no está
  if claude plugin list 2>/dev/null | grep -q "$PLUGIN"; then
    info "$PLUGIN ya instalado"
  elif claude plugin install "$PLUGIN" --scope user >/dev/null 2>&1; then
    info "$PLUGIN instalado"
  else
    warn "no se pudo instalar automáticamente. Instala con:"
    warn "  claude plugin marketplace add anthropics/claude-plugins-official"
    warn "  claude plugin install $PLUGIN --scope user"
  fi
  # 3) habilitar (el settings.json ya lo declara; esto lo fuerza por si estaba disabled)
  claude plugin enable "$PLUGIN" >/dev/null 2>&1 || true
else
  warn "claude CLI no encontrado; instala el plugin luego con:"
  warn "  claude plugin install $PLUGIN --scope user"
fi

step "Listo"
echo "  • Recarga tmux:  tmux source-file ~/.tmux.conf   (o Ctrl+b R)"
echo "  • Instala catppuccin en tmux: Ctrl+b I"
echo "  • La statusline de Claude aparece al abrir 'claude'."
echo "  • Skills (por-proyecto):  ./install-skills.sh /ruta/al/proyecto"
