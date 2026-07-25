# claude-setup

Mi configuración portable de **tmux** + **Claude Code** para replicarla en cualquier servidor.

## Uso rápido

En una máquina nueva:

```bash
git clone git@github.com:jcardila/claude-setup.git ~/claude-setup
cd ~/claude-setup
bash install.sh
```

O simplemente dile a una instancia de Claude Code:

> "Clona `github.com/jcardila/claude-setup` y sigue su `SETUP.md`."

Y Claude hace el resto. (Ver [`SETUP.md`](SETUP.md), escrito para que un agente lo ejecute.)

## Qué incluye

| Componente | Archivos | Notas |
|---|---|---|
| **tmux** | `tmux/tmux.conf`, `tmux/scripts/*` | Catppuccin Mocha, status bar arriba, git branch + dir corto. Requiere TPM (lo instala `install.sh`). |
| **statusline Claude** | `claude/statusline.sh` | 2 líneas: identidad (tmux · modelo · effort · cuenta · dir · git) + métricas en vivo (contexto · límites · líneas · costo). Catppuccin Mocha. Ver [Statusline](#statusline). Deps: `jq`, `git`, coreutils. |
| **hooks Claude** | `claude/hooks/*` | `needs-attention.sh`, `task-done.sh`. |
| **prefs Claude** | `claude/settings.portable.json` | Idioma ES, effort alto, **modo auto** (`defaultMode: auto`), **Remote Control al arranque** y **sin fallback automático de modelo**. Se **mergea** sin pisar permisos locales. |
| **plugin frontend-design** | (vía `install.sh`) | Marketplace `anthropics/claude-plugins-official` + `frontend-design@claude-plugins-official`, instalado a nivel usuario y habilitado. |
| **skills** | `claude/skills/*` | **Por-proyecto** — instalar con `install-skills.sh <proyecto>`. |

## Statusline

Dos líneas, colores Catppuccin Mocha:

```
tmux │ Opus 4.8 (1M context) · high │ tucuenta@correo.com │ ~/app-nodo │ main ~3 ?1 ↑2
▓▓▓░░░░░░░░░░░░░░ 142k/1.0M 45% │ 5h 32% 7d 8% │ +156 -23 │ $0.42
```

- **Línea 1 — identidad y ubicación:** indicador de tmux · modelo · effort ·
  cuenta de Claude · directorio · git (rama + `+`staged `~`modified `?`untracked
  `↑`ahead `↓`behind).
- **Línea 2 — métricas en vivo:** barra de contexto · `tokens/ventana` + `%`
  (aviso `200k+` al cruzar el umbral) · límites de tasa `5h`/`7d` · líneas `+/-`
  · costo estimado.

Detalles que lo hacen confiable:

- **Effort actual de verdad.** Se lee del transcript de la sesión (registra cada
  `/effort`, incluido el modo session-only `ultracode` que no se persiste en
  `settings.json`); fallback a `settings.json`.
- **Indicador de tmux.** `tmux` verde cuando la sesión corre dentro de tmux;
  alarma roja **`NO-TMUX`** cuando no (útil si se te olvida arrancarlo).
- **Cuenta en vivo.** Lee `~/.claude.json` en cada render → refleja la cuenta
  actual tras un `/login` a mitad de sesión.
- **Barra sin glyphs Unicode.** Usa bloques de color de fondo, así que no depende
  de que la fuente de la terminal tenga `█`/`░` (evita los `???`).
- **tmux-safe.** El cache de git es por-directorio (hash del path), sin colisiones
  entre panes.
- **Rápido** (~68ms): los 13 campos del JSON se extraen en una sola llamada a `jq`.
- **Fallback ASCII:** `export CLAUDE_STATUSLINE_ASCII=1` para terminales sin
  color de fondo truecolor.

## Modo auto

Las prefs incluyen `permissions.defaultMode: "auto"` → Claude arranca en **modo
auto**, el modo que se cicla con `Shift+Tab`. Es distinto de `acceptEdits` (ese
solo auto-acepta ediciones de archivo); `auto` es el modo automático amplio.
Valores válidos de `defaultMode` en Claude Code 2.1.x: `default`, `acceptEdits`,
`auto`, `plan`, `bypassPermissions`.

## Remote Control siempre encendido

```json
"remoteControlAtStartup": true
```

Es el mismo toggle que en `/config` aparece como **"Enable Remote Control for
all sessions"**. Con `true`, cada sesión levanta el bridge de Remote Control al
arrancar (lo que te deja retomarla desde `claude.ai/code` o el móvil) sin tener
que correr `claude --remote-control` / `/remote-control` a mano.

**Precedencia** (de mayor a menor), útil si alguna máquina no lo activa:

1. `disableRemoteControl: true` en los *managed settings* de la organización
   (`/etc/claude-code/managed-settings.json`) → apaga Remote Control por
   completo, gana sobre todo lo demás.
2. `remoteControlAtStartup: false` en `.claude/settings.json` del **proyecto** o
   en cualquier `settings.local.json` → apaga, gana sobre el nivel usuario.
3. Políticas / flags de la org.
4. **`~/.claude/settings.json`** ← aquí es donde lo pone este repo.
5. `~/.claude.json` (lo que escribe el `/config` interactivo).

`install.sh` avisa si detecta un `false` en (1) o (2).

Requisitos: sesión con login de **claude.ai** (suscripción activa). Con auth por
`ANTHROPIC_API_KEY` el bridge no arranca. Para diagnosticar: `claude
remote-control` imprime un checklist (API alcanzable, política de la org, login,
suscripción, scopes).

## Sin fallback de modelo cuando los safeguards marcan algo

```json
"switchModelsOnFlag": false
```

En `/config` es **"Switch models when a message is flagged"** (sección *Model &
output*), y viene en `true` por defecto. Con el default, si los safeguards marcan
un mensaje —por ejemplo trabajando con Fable 5— Claude Code **cambia solo a otro
modelo** para seguir la conversación. Con `false` no hay cambio silencioso: la
sesión **pausa y pregunta**, y tú decides.

Kill-switches equivalentes por entorno, por si los quieres en un server puntual:

| Variable | Efecto |
|---|---|
| `CLAUDE_CODE_DISABLE_REFUSAL_FALLBACK=1` | Apaga el mecanismo entero (ni siquiera ofrece el cambio). Más duro que el setting. |
| `CLAUDE_CODE_NO_MODEL_FALLBACK=1` | Prohíbe **cualquier** sustitución de modelo, incluida la de compactación. Puede hacer fallar `/compact` si tu política de modelos solo permite Fable 5. |

Este repo usa el setting (`switchModelsOnFlag: false`) y no las env vars: mantiene
el diálogo de consentimiento en vez de romper la sesión.

## Actualizar el setup en todos los servers

Editas aquí, `git push`, y en cada máquina `git pull`. Como `install.sh` usa
symlinks, los cambios en `tmux.conf` / `statusline.sh` / `hooks/` se aplican solos
(salvo `settings.json`, que se re-mergea corriendo `install.sh` de nuevo).

## Lo que NUNCA se versiona

`settings.local.json` (permisos por-máquina), `.credentials.json` (token de auth),
historial, sesiones. Ver `.gitignore`.
