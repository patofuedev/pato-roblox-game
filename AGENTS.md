# AGENTS.md

Guía para agentes de IA (y personas) que trabajen en este repositorio.
Juego de Roblox "Coin Collector" escrito en Luau, sincronizado con Rojo y publicado en Roblox por GitHub Actions mediante Open Cloud.

## Comandos

```bash
aftman install                                  # instala rojo, selene y stylua (versiones de aftman.toml)
rojo serve                                      # sincroniza con Roblox Studio (plugin de Rojo)
rojo build default.project.json -o game.rbxlx   # build completo del place
stylua src                                      # formatea (CI usa: stylua --check src)
selene src                                      # lint
jq empty default.project.json                   # valida el JSON del proyecto
```

Antes de dar un cambio por terminado, ejecuta lo mismo que el CI y comprueba que pasa:
`stylua --check src && selene src && rojo build default.project.json -o game.rbxlx`.

Entorno de desarrollo del equipo: **Kubuntu 26.04** (zsh). Roblox Studio corre con Vinegar (Flatpak), así que `rojo plugin install` no sirve: el plugin de Rojo se instala desde el Creator Store dentro de Studio.

No hay tests automatizados ni forma de ejecutar el juego fuera de Roblox Studio: el comportamiento en partida debe verificarlo una persona en Studio. Dilo explícitamente cuando no se haya probado.

## Mapa de Rojo (`default.project.json`)

| Carpeta | Instancia en Roblox | Tipo |
| --- | --- | --- |
| `src/server/` | `ServerScriptService.Server` | `Script` (por `init.server.luau`) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `LocalScript` (por `init.client.luau`) |
| `src/shared/` | `ReplicatedStorage.Shared` | `Folder` |

El mapa (`Workspace`: Baseplate, SpawnLocation, `Coins/Coin01..05`) también está definido en `default.project.json`. Los módulos se requieren por ruta de instancia, no de fichero:
`require(ReplicatedStorage.Shared.Config)`, `require(script.Services.CoinService)`, `require(script.Parent.LeaderstatsService)`.

## Arquitectura

- **Servidor**: `src/server/init.server.luau` carga los módulos de `Services/` en el orden de la lista `SERVICES` y llama a `Init()` en todos y después a `Start()` en todos. Un servicio nuevo es un módulo `XxxService.luau` con `Init`/`Start` opcionales, registrado en esa lista después de sus dependencias.
- **Cliente**: `src/client/init.client.luau` arranca los módulos de `Controllers/` (lista `CONTROLLERS`, método `Start()`). Los controladores solo se ocupan de la presentación (visuales, UI, sonido).
- **Config**: los valores de gameplay viven en `src/shared/Config.luau` (congelado con `table.freeze`). No metas números mágicos en los servicios; añade la clave a `Config`.
- **Monedas**: se detectan por el tag de CollectionService `Config.CoinTag` (`"Coin"`), no por ruta. Cualquier `BasePart` con ese tag es una moneda.
- **Estadísticas**: solo `LeaderstatsService` crea o modifica `leaderstats/Coins`. Los demás llaman a `AddCoins` / `GetCoins`.
- Sin frameworks (Knit, etc.) ni dependencias de Wally por ahora. No los añadas sin pedirlo.

Sistemas previstos (tienda, inventario, NPCs, quests, enemigos, DataStore, rankings, gamepasses, developer products): cada uno será un servicio en `Services/`, más un controlador si tiene UI. La persistencia irá en un `PlayerDataService` que alimente a `LeaderstatsService`. No los implementes si no se piden.

## Reglas de código

- Luau con `--!strict` en la primera línea de cada módulo.
- Formato: StyLua (`stylua.toml`), con tabulaciones y comillas dobles. Lint: Selene (`std = "roblox"`). Deben quedar con 0 errores y 0 warnings.
- Comentarios y mensajes en **español**. Cada módulo empieza con un bloque `--[[ ]]` que explica su responsabilidad.
- Usa `game:GetService(...)` al principio del módulo, `task.spawn`/`task.delay` (nunca `spawn`/`wait`/`delay`) e interpolación con backticks para los `warn`.
- **Autoridad del servidor**: el cliente nunca decide resultados de gameplay (monedas, compras, daño, recompensas). Todo lo que llegue de un `RemoteEvent` se valida en el servidor (tipo, rango, distancia, cooldown). Si se añaden remotes, se centralizan en `src/shared/Remotes.luau`.
- Evita las entregas duplicadas: bloquea el recurso (como `collectedCoins` en `CoinService`) antes de hacer cualquier otra cosa.

## Ramas y CI/CD

```text
feature/* ──PR──▶ develop ──PR──▶ main ──▶ deploy a Roblox
```

- `ci.yml`: se ejecuta en PRs a `main`/`develop` y en push a `develop`. Hace lint y build, y sube `game.rbxlx` como artifact. **No publica.**
- `publish-place.yml`: workflow reutilizable (`workflow_call`, input `environment`). Hace lint y build, y llama a `scripts/publish-place.sh` (Place Publishing API de Open Cloud).
- `deploy-dev.yml`: se ejecuta en push a `develop` y publica en el **Place DEV** (entorno `development`).
- `deploy.yml`: se ejecuta en push a `main` y publica en **producción** (entorno `production`).
- Trabaja en ramas `feature/*` creadas desde `develop`. No hagas commit ni push directo a `main`, porque cualquier push a `main` publica el juego a los jugadores.
- La instalación de herramientas está en la acción compuesta `.github/actions/setup-tools/`, que usan `ci.yml` y `publish-place.yml`.
- Los secretos se leen solo del entorno de GitHub (sin `secrets: inherit`). No añadas `secrets: inherit` ni secretos de repositorio: un entorno mal configurado podría publicar en el place equivocado.

## Seguridad (obligatorio)

- Secretos: `ROBLOX_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`, como secretos de los entornos `production` y `development`. Nunca los escribas en el repo, en logs, en `echo` ni con `set -x`. `publish-place.sh` pasa la key por `--header @<(...)` para que no aparezca en la línea de comandos. Mantén eso.
- Workflows con `permissions: contents: read`. No amplíes permisos sin justificarlo en un comentario.
- Actions fijadas por **SHA de commit**, con la versión en un comentario (`uses: actions/checkout@<sha> # v7.0.1`). Solo actions oficiales o de proyectos ampliamente mantenidos.
- Aftman se descarga en una versión fija y se verifica su SHA-256 en `setup-tools/action.yml`. Si actualizas la versión, actualiza también el hash.
- Las versiones de las herramientas están fijadas en `aftman.toml`. Cambiarlas es un cambio deliberado, que se hace en un PR.

## Cuidado con

- **El deploy reemplaza el place entero** por el resultado de `rojo build`. Lo que se edite solo en Studio y no esté en `src/` o en `default.project.json` se pierde en el siguiente deploy.
- Al cambiar `Name`s o rutas en `default.project.json`, revisa los `require` y las referencias por ruta que dependan de ellos.
- Las propiedades de `default.project.json` usan la sintaxis implícita de Rojo (`"Shape": "Cylinder"`, `"Tags": ["Coin"]`, vectores como arrays). Compruébalo siempre con `rojo build`.
- `game.rbxlx`, `sourcemap.json` y `.env*` están en `.gitignore`. No los versiones.
- Si el repo pasa a ser privado en un plan gratuito de GitHub, los secretos de entorno dejan de estar disponibles y los deploys fallan. Avísalo antes de cambiar la estrategia de secretos.

## Documentación

- `README.md`: documentación general del proyecto.
- `pendientes.md`: checklist de configuración y estado actual. Actualízalo cuando se complete un pendiente o aparezca uno nuevo, con la fecha en la sección "Estado actual".
- Al cambiar workflows, comandos o estructura, actualiza también `README.md` y este archivo.
