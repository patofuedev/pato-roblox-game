# Pato Roblox Game — Coin Collector

Juego base de Roblox desarrollado "como código": todo el juego vive en este repositorio, se sincroniza con Roblox Studio mediante [Rojo](https://rojo.space) y GitHub Actions lo publica automáticamente en Roblox con [Open Cloud](https://create.roblox.com/docs/cloud) cada vez que se hace merge a `main`.

Gameplay inicial: el jugador aparece en el centro del mapa, recoge monedas tocándolas, su contador `Coins` sube en el leaderboard y las monedas reaparecen a los pocos segundos.

---

## Arquitectura

```text
.
├── src/
│   ├── client/                          → StarterPlayer.StarterPlayerScripts.Client (LocalScript)
│   │   ├── init.client.luau             Arranca los controladores del cliente
│   │   └── Controllers/
│   │       └── CoinVisualController.luau  Giro visual de las monedas (solo cosmético)
│   ├── server/                          → ServerScriptService.Server (Script)
│   │   ├── init.server.luau             Arranca los servicios (Init → Start)
│   │   └── Services/
│   │       ├── LeaderstatsService.luau  Crea leaderstats y es el único que modifica Coins
│   │       └── CoinService.luau         Recogida y reaparición de monedas (autoritativo)
│   └── shared/                          → ReplicatedStorage.Shared (Folder)
│       └── Config.luau                  Valores de gameplay (tiempos, valores, distancias)
├── scripts/
│   └── publish-place.sh                 Publica un .rbxlx con la Place Publishing API
├── .github/
│   ├── actions/setup-tools/action.yml   Acción compuesta: instala Aftman + herramientas
│   └── workflows/
│       ├── ci.yml                       Lint + build en PRs y en develop (no publica)
│       ├── publish-place.yml            Reutilizable: build + publicación en el entorno indicado
│       ├── deploy-dev.yml               push a develop → Place DEV (entorno development)
│       └── deploy.yml                   push a main → Place de producción (entorno production)
├── default.project.json                 Mapa de Rojo: carpetas → instancias + mapa inicial
├── aftman.toml                          Versiones fijadas de rojo, selene y stylua
├── selene.toml / stylua.toml            Configuración de linter y formateador
└── .vscode/                             Extensiones y ajustes recomendados
```

### Principios

- **El servidor manda.** El cliente nunca decide cuántas monedas recibe. `CoinService` valida cada toque (jugador vivo, distancia máxima a la moneda) y usa un cerrojo por moneda para que no pueda entregarse dos veces.
- **Servicios y controladores.** El servidor se compone de *services* (`Init()` + `Start()`) y el cliente de *controllers* (`Start()`). Añadir un sistema nuevo = crear un módulo y registrarlo en la lista de `init.server.luau` / `init.client.luau`. Sin frameworks.
- **Un dueño por dato.** Solo `LeaderstatsService` toca los `IntValue`; los demás llaman a `AddCoins` / `GetCoins`. Cuando llegue DataStore, solo cambia ese punto.
- **Configuración centralizada.** Los números de gameplay viven en `src/shared/Config.luau` (congelado con `table.freeze`).
- **Monedas por tag.** Cualquier `BasePart` con el tag de CollectionService `Coin` funciona como moneda, ya sea del mapa o creada en tiempo de ejecución.

### Cómo crecerá

| Sistema futuro | Dónde encaja |
| --- | --- |
| DataStore | `Services/PlayerDataService.luau`, que carga/guarda y alimenta a `LeaderstatsService` |
| Tienda, gamepasses, developer products | `Services/ShopService.luau` / `MonetizationService.luau` + `Controllers/ShopController.luau` |
| Inventario, quests | `Services/InventoryService.luau`, `Services/QuestService.luau` |
| NPCs, enemigos | `Services/NpcService.luau`, `Services/EnemyService.luau` (+ modelos en `default.project.json` o `assets/`) |
| Rankings | `Services/LeaderboardService.luau` con `OrderedDataStore` |
| Comunicación cliente ↔ servidor | `src/shared/Remotes.luau` que crea/expone los `RemoteEvent`; el servidor valida siempre lo que recibe |

---

## Requisitos

| Herramienta | Para qué | Instalación |
| --- | --- | --- |
| [Roblox Studio](https://create.roblox.com/) | Probar y editar el juego | Descargar desde create.roblox.com (Windows / macOS) |
| [Aftman](https://github.com/LPGhatguy/aftman) | Instala las herramientas con la versión exacta del proyecto | Ver abajo |
| Rojo, Selene, StyLua | Sincronizar, lint y formato | `aftman install` (automático) |
| [VS Code](https://code.visualstudio.com/) | Editor | Al abrir el repo te sugerirá las extensiones de `.vscode/extensions.json` |
| Plugin de Rojo para Studio | Conectar Studio con `rojo serve` | `rojo plugin install` o desde el Creator Store |

### Instalar Aftman

1. Descarga el zip de tu sistema desde las [releases de Aftman](https://github.com/LPGhatguy/aftman/releases) (`aftman-0.3.0-windows-x86_64.zip`, `...-macos-aarch64.zip`, `...-linux-x86_64.zip`).
2. Descomprímelo y ejecuta:

   ```bash
   ./aftman self-install
   ```

3. Reinicia la terminal y, en la raíz del repo:

   ```bash
   aftman install
   rojo --version   # Rojo 7.7.1
   ```

   La primera vez Aftman pedirá confirmar que confías en cada herramienta.

> [Rokit](https://github.com/rojo-rbx/rokit), el sucesor de Aftman, también lee `aftman.toml`, por lo que `rokit install` funciona sin cambios.

### Instalar el plugin de Rojo en Studio

```bash
rojo plugin install
```

Reinicia Roblox Studio; verás el botón **Rojo** en la pestaña *Plugins*.

---

## Desarrollo local

1. Inicia el servidor de Rojo en la raíz del repo:

   ```bash
   rojo serve
   ```

   Por defecto escucha en `localhost:34872`.

2. Abre Roblox Studio con un *Baseplate* vacío (o el place real del juego).
3. *Plugins → Rojo → Connect*. Rojo sincroniza `src/` y el mapa de `default.project.json` en Studio.
4. Edita los archivos `.luau` en VS Code: los cambios aparecen en Studio al guardar.
5. Pulsa **Play** en Studio para probar.

> Regla de oro: el código se edita en VS Code, no en Studio. Lo que se cambie solo en Studio y no esté en `default.project.json` o `src/` no llega al repositorio.

Antes de abrir un PR, ejecuta las mismas comprobaciones que el CI:

```bash
stylua --check src   # formato (usa `stylua src` para corregirlo)
selene src           # lint
rojo build default.project.json -o game.rbxlx
```

---

## Build

```bash
rojo build default.project.json -o game.rbxlx
```

Genera `game.rbxlx`, el place completo (scripts + mapa), que puedes abrir directamente en Roblox Studio. El archivo está en `.gitignore`: es un artefacto, no código fuente.

---

## CI/CD

```text
feature/mi-funcion ──PR──▶ develop ──PR──▶ main
        │                    │              │
        └── CI (lint+build)  ├── CI         └── Deploy ──▶ Place de PRODUCCIÓN
                             └── Deploy DEV ──▶ Place DEV
```

| Workflow | Disparador | Qué hace | Publica |
| --- | --- | --- | --- |
| `ci.yml` | PR → `main`, PR → `develop`, push → `develop` | Instala herramientas, muestra versiones, valida `default.project.json`, StyLua, Selene, `rojo build`, sube `game.rbxlx` como artifact (7 días) | No |
| `deploy-dev.yml` | push → `develop` | Llama a `publish-place.yml` con el entorno `development` | Sí, en el Place DEV |
| `deploy.yml` | push → `main` | Llama a `publish-place.yml` con el entorno `production` | Sí, en producción |
| `publish-place.yml` | solo `workflow_call` | Lint, `rojo build`, publica la nueva versión del Place vía Open Cloud | — |

### Flujo de trabajo

1. `git switch develop && git switch -c feature/mi-funcion`
2. Commits + `git push -u origin feature/mi-funcion`
3. PR hacia `develop` → el CI debe pasar → merge.
4. El merge a `develop` publica automáticamente en el **Place DEV**: pruébalo ahí.
5. PR de `develop` hacia `main` → CI → merge → **deploy automático a producción**.

### Seguridad en GitHub Actions

- `permissions: contents: read` en todos los workflows (mínimo privilegio).
- Solo actions oficiales de GitHub (`actions/checkout`, `actions/cache`, `actions/upload-artifact`), fijadas por SHA de commit.
- Aftman se descarga en una versión fija y se verifica su SHA-256 antes de ejecutarlo; las herramientas salen de `aftman.toml`, que se revisa en cada PR.
- `persist-credentials: false` en el checkout: el token no queda guardado en `.git/config`.
- Los secretos de Roblox solo se exponen al paso de publicación de `publish-place.yml`. El CI de PRs no tiene acceso a ellos.
- Los secretos se leen **solo del entorno** (no hay `secrets: inherit`). Un entorno sin configurar falla, en lugar de publicar por error en otro place con secretos de repositorio.
- `scripts/publish-place.sh` envía la API key por un descriptor de fichero (no aparece en la línea de comandos) y nunca la imprime.
- `concurrency` impide dos deploys simultáneos al mismo entorno.

### Publicación (Roblox Open Cloud)

Se usa la [Place Publishing API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) oficial:

```http
POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published
x-api-key: <ROBLOX_API_KEY>
Content-Type: application/xml        # .rbxlx  (application/octet-stream para .rbxl)
```

Respuesta: `{ "versionNumber": 7 }`. El número de versión aparece en el resumen del job.

> La experiencia y el place deben existir de antemano (créalos publicando una vez desde Roblox Studio). La publicación reemplaza **todo** el place por lo que hay en el repo: lo editado solo en Studio se pierde.

---

## GitHub Secrets

Cada entorno de GitHub tiene sus propios tres secretos, con **los mismos nombres** y valores distintos. **Nunca** los escribas en el repositorio, en issues ni en logs.

| Secreto | `production` (rama `main`) | `development` (rama `develop`) |
| --- | --- | --- |
| `ROBLOX_API_KEY` | Key con permiso solo sobre la experiencia de producción | Key con permiso solo sobre la experiencia DEV |
| `ROBLOX_UNIVERSE_ID` | ID de la experiencia de producción | ID de la experiencia DEV |
| `ROBLOX_PLACE_ID` | ID del place de producción | ID del place DEV |

Usa **dos experiencias distintas** en Roblox (por ejemplo, "Coin Collector" y "Coin Collector [DEV]") y una API key por cada una, para que una key DEV filtrada no pueda tocar producción.

### 1. Obtener los IDs

1. Entra en el [Creator Dashboard](https://create.roblox.com/dashboard/creations).
2. En la tarjeta de tu experiencia: menú **⋯ → Copy Universe ID** → `ROBLOX_UNIVERSE_ID`.
3. Abre la experiencia → **Places** → menú **⋯** del place → **Copy Place ID** → `ROBLOX_PLACE_ID`.

### 2. Crear la API key

1. [Creator Dashboard → Open Cloud → API Keys](https://create.roblox.com/dashboard/credentials) → **Create API Key**.
   - Si la experiencia pertenece a un grupo, crea la key desde el grupo.
2. Nombre: por ejemplo `github-actions-deploy`.
3. **Access Permissions** → añade la API **universe-places**, selecciona tu experiencia y marca la operación **Write**.
4. **Security**: puedes dejar las IPs abiertas (`0.0.0.0/0`), ya que los runners de GitHub no tienen IP fija. Pon una fecha de expiración y rótala periódicamente.
5. **Save & Generate Key** y copia la key (solo se muestra una vez) → `ROBLOX_API_KEY`.

Concede únicamente ese permiso y esa experiencia: si la key se filtrara, el daño quedaría limitado a ese place.

### 3. Crear los entornos y guardar los secretos

Debe hacerlo alguien con permisos de **admin** en el repositorio.

**Desde la web:** *Settings → Environments → New environment*, crea `production` y `development`. En cada uno:

1. **Deployment branches and tags → Selected branches**: `main` para `production` y `develop` para `development`.
2. **Environment secrets → Add environment secret**: los tres secretos con los valores de ese entorno.
3. Opcional en `production`: **Required reviewers**, para aprobar cada publicación manualmente.

No crees estos secretos a nivel de repositorio (*Secrets and variables → Actions → Repository secrets*): los workflows no los leen.

**Desde la terminal** (`gh` autenticado con una cuenta admin; `gh secret set` pide cada valor sin mostrarlo):

```bash
R=repos/<owner>/<repo>
for e in production:main development:develop; do
  env=${e%%:*}; br=${e##*:}
  gh api -X PUT $R/environments/$env --input - <<<'{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}'
  gh api -X POST $R/environments/$env/deployment-branch-policies -f name=$br -f type=branch
  for s in ROBLOX_API_KEY ROBLOX_UNIVERSE_ID ROBLOX_PLACE_ID; do
    gh secret set $s --env $env --repo <owner>/<repo>
  done
done
```

Para probar el script localmente sin GitHub:

```bash
ROBLOX_API_KEY=... ROBLOX_UNIVERSE_ID=... ROBLOX_PLACE_ID=... ./scripts/publish-place.sh game.rbxlx
# ROBLOX_VERSION_TYPE=Saved guarda la versión sin publicarla a los jugadores
```

---

## Entornos

| Entorno | Rama | Workflow | Place |
| --- | --- | --- | --- |
| `development` | `develop` | `deploy-dev.yml` | Experiencia DEV |
| `production` | `main` | `deploy.yml` | Experiencia pública |

Ambos workflows llaman a `publish-place.yml` y solo cambian el entorno. Para añadir otro entorno (por ejemplo, `staging`): crea el entorno en GitHub con sus tres secretos y un workflow como `deploy-dev.yml` con el disparador y `environment:` correspondientes.
