---
name: analizar-issue
description: Usar al EMPEZAR a trabajar en uno o varios issues de GitHub del repo. Analiza el/los issue(s) a fondo — descripción, TODOS los comentarios y las imágenes adjuntas (las descarga y las lee visualmente, son clave para entender el pedido) — y luego AUTO-ASIGNA el issue al usuario para avisar a los otros devs que ya alguien lo tomó. Dispara con frases como "voy a trabajar en el issue #N", "analiza el issue #N", "arranquemos el #N y el #M", "asígname el issue #N".
---

# Analizar issue de GitHub y auto-asignarlo

Cuando el usuario va a empezar a trabajar en un issue de `ardisa-sa/magento-hyva`,
este skill lo prepara: trae el issue completo (descripción + **todos** los comentarios
+ **imágenes adjuntas**, que suelen ser críticas para entender el pedido) y luego
lo **auto-asigna** al usuario para que los demás devs sepan que ya está tomado.

El driver `fetch-issue.sh` hace el trabajo pesado (solo lectura): trae los datos
vía `gh` y **descarga las imágenes autenticadas** (en repos privados las URLs de
`user-attachments` dan 404 sin token), dejándolas como archivos locales listos para
leer con la herramienta Read.

> Rutas relativas a la raíz del repo: `/var/www/magento2`.

## Prerequisitos

`gh`, `jq`, `curl` y `file` ya están instalados. `gh` debe estar autenticado:

```bash
gh auth status   # debe decir "Logged in"; si no: gh auth login
```

## Flujo (lo que debe hacer el agente)

### 1. Traer y descargar el/los issue(s)

```bash
.claude/skills/analizar-issue/fetch-issue.sh 25
# Varios a la vez:
.claude/skills/analizar-issue/fetch-issue.sh 19 22 24
```

Imprime metadata (estado, autor, labels, asignados, milestone, URL), la descripción,
**todos los comentarios** (con autor y fecha) y la lista de imágenes descargadas en
`/tmp/gh-issue-<N>/img-*.png` (o `.jpg`/`.gif`/`.webp`).

### 2. Leer CADA imagen descargada

Por cada ruta `img-*` que imprimió el script, usar la herramienta **Read** sobre el
archivo para verla. No saltarse esto: las capturas muestran el bug o el diseño pedido
y a menudo dicen más que el texto.

```
Read /tmp/gh-issue-25/img-1.png
Read /tmp/gh-issue-25/img-2.png
```

### 4. Auto-asignar el issue al usuario (AUTOMÁTICO — no preguntar)

**SIEMPRE, como parte del flujo, asignar el/los issue(s) a la cuenta autenticada
inmediatamente después de traerlos. NO preguntar ni pedir confirmación** — el propósito
del skill es justamente avisar a los otros devs que el issue ya está tomado, así que la
asignación debe pasar sí o sí. `@me` se resuelve a la cuenta de `gh` (aquí: `jcardila`):

```bash
gh issue edit 25 --add-assignee @me
```

Para varios issues, asignar cada número (`gh issue edit 19 --add-assignee @me`, etc.).
Hacerlo aunque el usuario haya enmarcado el pedido como "analiza" o "recomienda": tomar
el issue para trabajarlo implica asignárselo. Es reversible si te equivocás de issue:

```bash
gh issue edit 25 --remove-assignee @me
```

### 5. Sintetizar el análisis

Presentarle al usuario, en lenguaje claro: qué pide el issue, qué aporta cada
comentario, qué muestran las imágenes, y qué partes del código de Magento/Hyva
probablemente toca. Si algo del pedido es ambiguo, decirlo antes de codificar.

## Gotchas

- **Imágenes en repo privado → 404 sin auth.** `curl` plano contra
  `github.com/user-attachments/assets/<uuid>` devuelve `404`. Hay que mandar
  `-H "Authorization: token $(gh auth token)"`. El driver ya lo hace; si descargás
  una imagen a mano, no olvides el header.
- **Dos formatos de imagen en los issues.** Markdown `![alt](url)` (ej. #19) y HTML
  `<img src="url">` (ej. #25). Ambos apuntan a `user-attachments/assets/<uuid>`
  **sin extensión** en la URL — el driver detecta el tipo real con `file` y renombra
  a `.png`/`.jpg`/etc. para que Read las reconozca.
- **Read necesita la extensión correcta.** Por eso el script no deja los archivos como
  `.bin`; si ves un `img-N.bin` es que `file` no reconoció el formato (revisar a mano).
- **Auto-asignar es visible para otros devs** (aparece en la UI de GitHub). Es el
  objetivo del skill, pero es una acción que otros ven; si fue por error, revertir con
  `--remove-assignee @me`.
- **`gh issue edit ... --add-assignee` es idempotente:** reasignar a alguien que ya
  está asignado no falla ni duplica.

## Troubleshooting

| Síntoma | Causa / fix |
|---|---|
| `ERROR: 'gh' no está autenticado` | Correr `gh auth login`. |
| `img-N: HTTP 404` en la salida del driver | URL de adjunto expiró o el token no tiene scope `repo`. Verificar `gh auth status` (necesita scope `repo`). |
| `img-N.bin` en vez de `.png` | `file` no reconoció el binario (puede ser HTML de error de GitHub). Abrir el `.bin` para ver qué devolvió. |
| El issue no muestra comentarios pero sabés que tiene | Confirmar el número de issue; `gh issue view <N> --comments` para verlo crudo. |
