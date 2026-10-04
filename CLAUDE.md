# CLAUDE.md

Las instrucciones del proyecto están en AGENTS.md (compartidas con otros agentes de IA):

@AGENTS.md

## Específico de Claude Code

- Ejecuta `stylua --check src && selene src && rojo build default.project.json -o game.rbxlx` antes de dar un cambio por terminado. Si las herramientas no están en el PATH, ejecuta antes `aftman install`.
- No hagas commit, push ni merge a `main` sin confirmación explícita: un push a `main` publica el juego en Roblox.
- Los commits y PRs van contra `develop`, desde ramas `feature/*`.
