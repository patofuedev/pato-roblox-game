# Pendientes

Lista de lo que falta para tener el flujo completo funcionando:
código en GitHub → CI → deploy automático a Roblox, y desarrollo local en **Kubuntu 26.04**.

- [ ] 1. Crear las experiencias en Roblox (producción y DEV)
- [ ] 2. Obtener los IDs y crear las API keys de Open Cloud
- [ ] 3. Guardar los secretos en los entornos de GitHub
- [ ] 4. Configurar `gh` con la cuenta dueña del repo y abrir el PR `develop → main`
- [ ] 5. Instalar el entorno local en Kubuntu
- [ ] 6. Probar el juego en Roblox Studio
- [ ] 7. Hacer merge del PR y verificar el primer deploy

---

## 1. Crear las experiencias en Roblox

Se necesitan **dos experiencias separadas**, para que una key DEV filtrada nunca pueda tocar producción.

| Entorno | Nombre sugerido | Rama de GitHub |
| --- | --- | --- |
| `production` | Coin Collector | `main` |
| `development` | Coin Collector [DEV] | `develop` |

Para cada una:

1. Abre Roblox Studio (ver sección 5 para instalarlo en Kubuntu).
2. **New → Baseplate**.
3. **File → Publish to Roblox → Create new experience** y ponle el nombre de la tabla.
4. En la experiencia DEV, si no quieres que sea pública: [Creator Dashboard](https://create.roblox.com/dashboard/creations) → experiencia → **Configure → Privacy: Private**.

> El contenido da igual: el primer deploy reemplaza todo el place con lo que hay en el repositorio.

## 2. Obtener los IDs y crear las API keys

Repite estos pasos para **cada** experiencia (producción y DEV) y apunta los valores en un lugar seguro, como tu gestor de contraseñas. **Nunca** en el repo ni en un chat.

### IDs

1. [Creator Dashboard → Creations](https://create.roblox.com/dashboard/creations).
2. En la tarjeta de la experiencia: **⋯ → Copy Universe ID** → valor de `ROBLOX_UNIVERSE_ID`.
3. Abre la experiencia → **Places** → **⋯** del place inicial → **Copy Place ID** → valor de `ROBLOX_PLACE_ID`.

### API key de Open Cloud

1. [Creator Dashboard → Open Cloud → API Keys](https://create.roblox.com/dashboard/credentials) → **Create API Key**.
   - Si la experiencia pertenece a un grupo, crea la key desde ese grupo (selector arriba a la izquierda).
2. **Name**: `github-actions-production` o `github-actions-development`.
3. **Access Permissions → Add API System → `universe-places`**:
   - **Experience**: selecciona **solo** la experiencia correspondiente.
   - **Operations**: marca **Write**.
4. **Security**:
   - **Accepted IP Addresses**: `0.0.0.0/0` (los runners de GitHub no tienen IP fija).
   - **Expiration**: pon una fecha (por ejemplo, 90 días) y anota cuándo hay que rotarla.
5. **Save & Generate Key** → copia la key. **Solo se muestra una vez** → valor de `ROBLOX_API_KEY`.

## 3. Guardar los secretos en GitHub

Hazlo con la cuenta **patofuedev** (admin del repo). Los entornos `production` y `development` ya existen.

Para cada entorno: **Settings → Environments → `<entorno>`**.

1. **Environment secrets → Add environment secret**, con estos tres nombres exactos:

   | Nombre | Valor |
   | --- | --- |
   | `ROBLOX_API_KEY` | La API key de ese entorno |
   | `ROBLOX_UNIVERSE_ID` | El Universe ID de ese entorno |
   | `ROBLOX_PLACE_ID` | El Place ID de ese entorno |

2. **Deployment branches and tags → Selected branches and tags → Add**:
   - `production` → `main`
   - `development` → `develop`

3. Opcional en `production`: **Required reviewers**, para aprobar cada publicación manualmente.

> ⚠️ Créalos **dentro del entorno**, no en *Secrets and variables → Actions → Repository secrets*. Los workflows solo leen los secretos del entorno.

Verificación: re-ejecutar el último **Deploy DEV** (`gh run rerun 37234416447`, o desde la pestaña *Actions → Re-run jobs*). Debe terminar en verde con `versionNumber=...` en el resumen.

## 4. `gh` con la cuenta correcta y PR a main

Ahora `gh` está conectado como `alvarockcl`, que solo tiene permiso de lectura en el repo. Para abrir PRs y gestionar entornos:

```bash
gh auth login        # GitHub.com → HTTPS → navegador → cuenta patofuedev
gh auth status       # comprobar que la cuenta activa es patofuedev
```

Después, abrir el PR `develop → main` (o desde la web:
https://github.com/patofuedev/pato-roblox-game/compare/main...develop?expand=1).

> No hagas merge hasta completar la sección 3: el merge a `main` lanza el deploy a producción.

---

## 5. Entorno local en Kubuntu 26.04

### 5.1 Paquetes base

```bash
sudo apt update
sudo apt install -y git curl unzip jq gh
```

### 5.2 Roblox Studio (vía Vinegar)

Roblox Studio **no tiene versión oficial para Linux**. Se ejecuta con [Vinegar](https://vinegarhq.org), un proyecto comunitario activo y distribuido por Flathub, que usa Wine por debajo.

Kubuntu no trae Flatpak por defecto:

```bash
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

**Reinicia la sesión** (o el equipo) y luego:

```bash
flatpak install -y flathub org.vinegarhq.Vinegar
flatpak run org.vinegarhq.Vinegar   # la primera vez descarga e instala Studio
```

Después aparece **Roblox Studio** en el menú de aplicaciones. Inicia sesión con tu cuenta de Roblox.

> Vinegar no es oficial: una actualización de Roblox puede romperlo temporalmente. Si pasa, actualízalo con `flatpak update` o mira los issues en https://github.com/vinegarhq/vinegar.

### 5.3 Aftman + Rojo, Selene y StyLua

```bash
cd /tmp
curl -sSfLO https://github.com/LPGhatguy/aftman/releases/download/v0.3.0/aftman-0.3.0-linux-x86_64.zip
echo "194fe81e24ae7cc1f3141fd1d42db6cb60f03d42735d12ae865fe2db11ea6f0e  aftman-0.3.0-linux-x86_64.zip" | sha256sum --check
unzip -o aftman-0.3.0-linux-x86_64.zip
./aftman self-install
rm aftman aftman-0.3.0-linux-x86_64.zip
```

Tu shell es **zsh**. Si al abrir otra terminal `aftman` no se encuentra, añade esto al PATH:

```bash
echo 'export PATH="$HOME/.aftman/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Instala las herramientas del proyecto (pedirá confirmar que confías en cada una):

```bash
cd ~/Documents/PATTRICIO/pato-roblox-game
aftman install
rojo --version     # Rojo 7.7.1
selene --version   # selene 0.32.0
stylua --version   # stylua 2.5.2
```

### 5.4 VS Code

```bash
cd /tmp
curl -sSfL -o code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo apt install -y ./code.deb   # añade también el repositorio de Microsoft para actualizaciones
rm code.deb
```

Abre el proyecto con `code ~/Documents/PATTRICIO/pato-roblox-game` y acepta **Install** en las extensiones recomendadas:

- Rojo (`evaera.vscode-rojo`)
- Luau Language Server (`johnnymorganz.luau-lsp`)
- StyLua (`johnnymorganz.stylua`)
- Selene (`kampfkarren.selene-vscode`)

### 5.5 Plugin de Rojo en Studio

`rojo plugin install` está pensado para Windows/macOS y no encuentra Studio dentro de Vinegar. Instálalo desde Studio:

1. Roblox Studio → pestaña **Toolbox** (o **View → Toolbox**) → **Creator Store → Plugins**.
2. Busca **Rojo** (publicado por *Rojo*, el oficial) → **Install**.
3. Debe ser una versión **7.7.x** (compatible con `rojo 7.7.1`). Si Rojo avisa de incompatibilidad de versión al conectar, actualiza el plugin.

---

## 6. Probar el juego en Studio

```bash
cd ~/Documents/PATTRICIO/pato-roblox-game
rojo serve
```

1. Abre Roblox Studio → **New → Baseplate**.
2. Pestaña **Plugins → Rojo → Connect** (por defecto `localhost:34872`).
3. Pulsa **Play** y comprueba:
   - [ ] El jugador aparece en el centro (SpawnLocation).
   - [ ] Hay 5 monedas doradas girando.
   - [ ] Al tocar una, desaparece y `Coins` sube en 1 en el leaderboard (arriba a la derecha).
   - [ ] La moneda reaparece a los 5 segundos.
   - [ ] La consola (**View → Output**) muestra `[Server] Servicios iniciados` y ningún error.

Antes de cada PR, ejecuta lo mismo que el CI:

```bash
stylua --check src && selene src && rojo build default.project.json -o game.rbxlx
```

## 7. Primer deploy a producción

1. Las secciones 3 y 4 deben estar completas.
2. Haz merge del PR `develop → main`.
3. En **Actions → Deploy**, el job debe terminar en verde y mostrar el `versionNumber` publicado.
4. Abre la experiencia de producción en Roblox y comprueba que tiene el mapa con las monedas.
