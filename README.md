# claude-setup

Mi configuración portable de **tmux** + **Claude Code** para replicarla en cualquier servidor.

## Uso rápido

En una máquina nueva:

```bash
git clone git@github.com:TU-USUARIO/claude-setup.git ~/claude-setup
cd ~/claude-setup
bash install.sh
```

O simplemente decile a una instancia de Claude Code:

> "Clona `github.com/TU-USUARIO/claude-setup` y seguí su `SETUP.md`."

Y Claude hace el resto. (Ver [`SETUP.md`](SETUP.md), escrito para que un agente lo ejecute.)

## Qué incluye

| Componente | Archivos | Notas |
|---|---|---|
| **tmux** | `tmux/tmux.conf`, `tmux/scripts/*` | Catppuccin Mocha, status bar arriba, git branch + dir corto. Requiere TPM (lo instala `install.sh`). |
| **statusline Claude** | `claude/statusline.sh` | Modelo · directorio · barra de contexto con colores Catppuccin. Deps: `jq`, `git`, `sed`. |
| **hooks Claude** | `claude/hooks/*` | `needs-attention.sh`, `task-done.sh`. |
| **prefs Claude** | `claude/settings.portable.json` | Idioma ES, effort alto, **modo auto** (`defaultMode: auto`). Se **mergea** sin pisar permisos locales. |
| **plugin frontend-design** | (vía `install.sh`) | Marketplace `anthropics/claude-plugins-official` + `frontend-design@claude-plugins-official`, instalado a nivel usuario y habilitado. |
| **skills** | `claude/skills/*` | **Por-proyecto** — instalar con `install-skills.sh <proyecto>`. |

## Modo auto

Las prefs incluyen `permissions.defaultMode: "auto"` → Claude arranca en **modo
auto**, el modo que se cicla con `Shift+Tab`. Es distinto de `acceptEdits` (ese
solo auto-acepta ediciones de archivo); `auto` es el modo automático amplio.
Valores válidos de `defaultMode` en Claude Code 2.1.x: `default`, `acceptEdits`,
`auto`, `plan`, `bypassPermissions`.

## Actualizar el setup en todos los servers

Editás acá, `git push`, y en cada máquina `git pull`. Como `install.sh` usa
symlinks, los cambios en `tmux.conf` / `statusline.sh` / `hooks/` se aplican solos
(salvo `settings.json`, que se re-mergea corriendo `install.sh` de nuevo).

## Lo que NUNCA se versiona

`settings.local.json` (permisos por-máquina), `.credentials.json` (token de auth),
historial, sesiones. Ver `.gitignore`.
