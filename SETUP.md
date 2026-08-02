# SETUP — instrucciones para Claude Code

> Este archivo está escrito para que un agente de Claude Code lo lea y lo ejecute.
> Si el usuario te dijo algo como **"configura mi setup así"** y te pasó este repo,
> sigue estos pasos en orden.

## Qué vas a instalar
1. **tmux**: `~/.tmux.conf` + scripts de status bar (dir corto + git branch) con tema
   Catppuccin Mocha, vía TPM.
2. **Claude Code (nivel usuario)**: `statusline.sh`, `hooks/`, y prefs portables
   mergeadas en `~/.claude/settings.json` (incluye **modo auto** = `permissions.defaultMode: auto`,
   **Remote Control automático** = `remoteControlAtStartup: true`, **sin cambio
   automático de modelo cuando los safeguards marcan un mensaje** = `switchModelsOnFlag: false`,
   y **retención de historial de conversaciones a 365 días** = `cleanupPeriodDays: 365`
   (el default de Claude Code es 30 días: borra los transcripts `.jsonl` de
   `~/.claude/projects/` más viejos que eso al arrancar, lo que hace que `claude --resume`
   pierda conversaciones antiguas).
   También agrega el marketplace `anthropics/claude-plugins-official` e instala/habilita
   el plugin **`frontend-design@claude-plugins-official`** a nivel usuario.
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
Luego, **dentro de tmux**, instala el plugin Catppuccin: `Ctrl+b` y después `I` (i mayúscula).
Esto no es automatizable desde fuera de tmux; hay que hacerlo en una sesión tmux viva.

### 4. Skills (solo si el usuario las quiere en este proyecto)
Las skills son **por-proyecto**. Pregunta al usuario en qué proyecto las quiere, o usa el actual:
```bash
bash install-skills.sh /ruta/al/proyecto
```

### 5. Verificar
- `readlink ~/.claude/statusline.sh` debe apuntar a este repo.
- Abre `claude`: la statusline (modelo · dir · barra de contexto) debe aparecer,
  y debe arrancar en **modo auto** (automático).
- `tmux` debe mostrar la status bar arriba con git branch + dir + sesión.
- `jq '{remoteControlAtStartup, switchModelsOnFlag, cleanupPeriodDays}' ~/.claude/settings.json`
  debe dar `true`, `false` y `365` respectivamente. Los dos primeros se ven en `/config` como
  *"Enable Remote Control for all sessions"* y *"Switch models when a message is flagged"*.
- Si Remote Control no arranca: `claude remote-control` imprime un checklist
  (política de la org `disableRemoteControl`, login de claude.ai, suscripción,
  scopes). Ojo también con un `remoteControlAtStartup:false` en el
  `.claude/settings.json` del proyecto o en un `settings.local.json` — esos
  scopes ganan sobre el nivel usuario. `install.sh` lo avisa.

## Lo que este repo NO toca (a propósito)
- `~/.claude/settings.local.json` — permisos específicos de cada máquina.
- `~/.claude/.credentials.json` — token de sesión (nunca se versiona).
- Historial, sesiones, tasks, telemetría.
