# SETUP — instrucciones para Claude Code

> Este archivo está escrito para que un agente de Claude Code lo lea y lo ejecute.
> Si el usuario te dijo algo como **"configura mi setup así"** y te pasó este repo,
> seguí estos pasos en orden.

## Qué vas a instalar
1. **tmux**: `~/.tmux.conf` + scripts de status bar (dir corto + git branch) con tema
   Catppuccin Mocha, vía TPM.
2. **Claude Code (nivel usuario)**: `statusline.sh`, `hooks/`, y prefs portables
   mergeadas en `~/.claude/settings.json` (incluye **modo auto** = `permissions.defaultMode: acceptEdits`).
3. **Skills** (opcional, **por-proyecto**): se copian dentro del `.claude/skills/`
   del proyecto que el usuario indique.

## Pasos

### 1. Verificar dependencias
Necesita `tmux git jq sed`. Si falta alguno:
```bash
sudo apt install tmux git jq
```

### 2. Correr el instalador principal (idempotente)
```bash
bash install.sh
```
Esto crea symlinks (respaldando cualquier archivo previo como `*.bak-<timestamp>`),
clona TPM si falta, y mergea las prefs en `settings.json` **sin pisar** los permisos
locales del usuario.

### 3. Activar tmux
```bash
tmux source-file ~/.tmux.conf   # o dentro de tmux: Ctrl+b R
```
Luego, **dentro de tmux**, instalar el plugin Catppuccin: `Ctrl+b` y después `I` (i mayúscula).
Esto no es automatizable desde fuera de tmux; hay que hacerlo en una sesión tmux viva.

### 4. Skills (solo si el usuario las quiere en este proyecto)
Las skills son **por-proyecto**. Preguntá al usuario en qué proyecto las quiere, o usá el actual:
```bash
bash install-skills.sh /ruta/al/proyecto
```

### 5. Verificar
- `readlink ~/.claude/statusline.sh` debe apuntar a este repo.
- Abrí `claude`: la statusline (modelo · dir · barra de contexto) debe aparecer,
  y debe arrancar en **modo auto** (auto-aceptar ediciones).
- `tmux` debe mostrar la status bar arriba con git branch + dir + sesión.

## Lo que este repo NO toca (a propósito)
- `~/.claude/settings.local.json` — permisos específicos de cada máquina.
- `~/.claude/.credentials.json` — token de sesión (nunca se versiona).
- Historial, sesiones, tasks, telemetría.
