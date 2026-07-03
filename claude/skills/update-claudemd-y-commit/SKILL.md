---
name: update-claudemd-y-commit
description: Cierra una sesión de trabajo cuando el usuario confirma que algo está funcionando bien y que quiere actualizar CLAUDE.md y hacer commit de los cambios. Primero actualiza CLAUDE.md con aprendizajes clave de la sesión, luego hace commit únicamente de los archivos modificados durante esta sesión, con un mensaje que represente el conjunto completo del trabajo realizado (no solo lo último).
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

4. Sigue al pie de la letra las reglas de git commits ya definidas en CLAUDE.md (Conventional Commits, español, preguntar usuario/email antes de commitear).
5. **No incluyas referencias a Claude, a la sesión de AI, ni a herramientas de asistencia** en el mensaje.

## Paso 4 — Confirmación previa al commit

Antes de ejecutar el `git commit`, muéstrame:

- La lista final de archivos a commitear
- El mensaje de commit propuesto (asunto + cuerpo si aplica)
- Pregunta con qué nombre y email firmar (según las reglas de CLAUDE.md)

Espera mi confirmación. No commitees sin que yo apruebe explícitamente.

## Paso 5 — Reporte final

Después del commit exitoso, muestra:

- Hash corto del commit y mensaje
- Resumen de qué se actualizó en CLAUDE.md (o "sin cambios" si no aplicó)
- Lista de archivos pendientes que **quedaron sin commitear** y por qué (ej. "estos archivos están modificados pero no fueron tocados en esta sesión — probablemente sesión paralela")