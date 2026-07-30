---
name: update-claudemd-y-commit
description: Cierra una sesión de trabajo cuando el usuario confirma que algo está funcionando bien y que quiere actualizar CLAUDE.md y hacer commit de los cambios. Primero actualiza CLAUDE.md con aprendizajes clave de la sesión, luego hace commit únicamente de los archivos modificados durante esta sesión, con un mensaje que represente el conjunto completo del trabajo realizado (no solo lo último). Si la sesión resolvió issues de GitHub, los cierra desde el propio commit con Closes #N.
---

# Actualizar CLAUDE.md y hacer commit de la sesión

El usuario ha validado que la implementación está funcionando. Ejecuta los siguientes pasos en orden estricto.

## Paso 1 — Actualizar CLAUDE.md

Revisa **toda la sesión** (desde el inicio) e identifica si hay:

- Aprendizajes técnicos clave: gotchas, patrones que funcionaron, decisiones de arquitectura
- Convenciones del proyecto que se establecieron o aclararon en esta sesión
- Comandos, paths, configuraciones o dependencias importantes que conviene documentar
- Errores comunes a evitar a futuro

Si encuentras algo significativo, edita CLAUDE.md. Si no, dilo explícitamente ("no hay aprendizajes nuevos que ameriten actualizar CLAUDE.md") y continúa. **No fuerces actualizaciones por compromiso.**

## Paso 2 — Identificar archivos modificados EN ESTA SESIÓN (crítico)

Esta es la regla más importante del skill. **Puede haber otra sesión de trabajo en paralelo** con cambios pendientes que no deben entrar a este commit.

1. Corre `git status` para ver todos los cambios pendientes (staged y unstaged).
2. Genera mentalmente la lista de archivos que **tú (Claude) editaste, creaste o eliminaste en esta sesión**. Apóyate en tu historial de tool calls (Edit, Write, etc.) durante la conversación.
3. Compara ambas listas:
   - **Archivos en `git status` que sí tocaste en la sesión** → entran al commit
   - **Archivos en `git status` que NO tocaste en la sesión** → NO entran al commit (probablemente son de otra sesión paralela)
4. Si hay algún archivo del que tengas duda, **pregunta al usuario antes de incluirlo o excluirlo**. No asumas.
5. Muestra al usuario la lista propuesta de archivos a commitear ANTES de hacer `git add`, con un breve resumen de por qué cada uno entra.

**Nunca uses `git add .` ni `git add -A` en este skill.** Siempre `git add <archivo1> <archivo2> ...` con los archivos específicos identificados.

## Paso 3 — Construir el mensaje de commit representativo del total

El mensaje debe reflejar **el conjunto completo del trabajo de la sesión**, no solo lo último corregido. Es común que una sesión tenga muchos intercambios resolviendo problemas iterativos, y el mensaje suele terminar sesgado al último fix. Evita ese sesgo:

1. Revisa la conversación de principio (o desde el último commit realizado en la sesión) a fin e identifica todos los cambios significativos: bugs corregidos, features agregados, refactors, configs ajustadas, docs actualizadas, etc.
2. Determina cuál es el cambio **predominante** o el objetivo principal de la sesión — ese define el prefijo Conventional Commits.
3. Si la sesión cubrió varios tipos de cambios (ej. un fix más un pequeño refactor más actualización de docs), usa el cuerpo del mensaje para listarlos:

```
   feat: <descripción del cambio principal>

   - <cambio secundario 1>
   - <cambio secundario 2>
   - <cambio secundario 3>
```

4. **Si la sesión resolvió issues de GitHub, ciérralos desde el propio commit.** Al final del cuerpo, tras una línea en blanco, una línea por issue:

```
   feat: <descripción del cambio principal>

   - <cambio secundario 1>
   - <cambio secundario 2>

   Closes #31
   Closes #32
```

   Cuatro reglas que se pagan caro si se ignoran:

   - **La palabra clave va en CADA línea.** `Closes #31 y #32` cierra solo el primero, y un `fix(#34):` en el asunto no cierra nada: es una etiqueta, no una instrucción. Pasó de verdad — cinco issues siguieron abiertos con el trabajo implementado, desplegado y en producción, porque el commit los nombraba como `feat(#35)` / `fix(#34)` en vez de usar la palabra clave.
   - **Solo cierra lo que quedó resuelto de punta a punta.** Si la sesión avanzó una parte del issue, usa `Refs #31`: enlaza el commit sin cerrarlo. Cerrar algo a medias es peor que no cerrarlo, porque nadie vuelve a mirarlo.
   - **Verifica los números contra la realidad, no contra tu memoria de la conversación:** `gh issue list --state open`. Un número equivocado cierra el issue de otra persona, y el aviso le llega a todo el que lo siga.
   - **GitHub cierra el issue cuando el commit llega a la rama por defecto**, es decir al hacer push (aquí se commitea directo a `main`) o al mergear el PR. Un commit que se queda local no cierra nada todavía.

   Para trabajo YA commiteado en el pasado sin la palabra clave, el commit nuevo no sirve: ciérralos a mano con `gh issue close <n> --comment "<qué quedó implementado> · commit <sha> · versión desplegada <build-id>"`.

5. Sigue al pie de la letra las reglas de git commits ya definidas en CLAUDE.md (Conventional Commits, español, preguntar usuario/email antes de commitear).
6. **No incluyas referencias a Claude, a la sesión de AI, ni a herramientas de asistencia** en el mensaje. Los `Closes #N` sí van: son trazabilidad del proyecto, no de la herramienta.

## Paso 4 — Confirmación previa al commit

Antes de ejecutar el `git commit`, muéstrame:

- La lista final de archivos a commitear
- El mensaje de commit propuesto (asunto + cuerpo si aplica)
- **Los issues que se van a cerrar**, con su título, para que yo pueda vetar alguno: cerrar es visible para todo el equipo
- Pregunta con qué nombre y email firmar (según las reglas de CLAUDE.md)

Espera mi confirmación. No commitees sin que yo apruebe explícitamente.

## Paso 5 — Reporte final

Después del commit exitoso, muestra:

- Hash corto del commit y mensaje
- Resumen de qué se actualizó en CLAUDE.md (o "sin cambios" si no aplicó)
- Lista de archivos pendientes que **quedaron sin commitear** y por qué (ej. "estos archivos están modificados pero no fueron tocados en esta sesión — probablemente sesión paralela")
- Si el commit lleva `Closes #N`: **los issues NO están cerrados todavía** — lo estarán al hacer push. Dilo así de claro y ofrece hacerlo. Después del push, comprueba que de verdad se cerraron (`gh issue list --state open`) en vez de darlo por hecho: si la rama no es la de por defecto, GitHub no cierra nada.
