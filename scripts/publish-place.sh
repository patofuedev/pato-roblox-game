#!/usr/bin/env bash
#
# Publica un archivo de place (.rbxlx / .rbxl) como nueva versión de un Place
# usando la Place Publishing API de Roblox Open Cloud:
#
#   POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published
#
# Docs: https://create.roblox.com/docs/cloud/guides/usage-place-publishing
# La API key necesita el permiso "universe-places" → Write para ese universo.
#
# Uso:
#   ROBLOX_API_KEY=... ROBLOX_UNIVERSE_ID=... ROBLOX_PLACE_ID=... \
#     ./scripts/publish-place.sh game.rbxlx
#
# Variables opcionales:
#   ROBLOX_VERSION_TYPE  Published (por defecto) | Saved (guarda sin publicar)
#
set -euo pipefail

place_file="${1:-game.rbxlx}"
version_type="${ROBLOX_VERSION_TYPE:-Published}"

fail() {
	echo "::error::$*" >&2
	exit 1
}

# --- Validación de entradas (sin imprimir nunca la API key) -----------------
[[ -n "${ROBLOX_API_KEY:-}" ]] || fail "ROBLOX_API_KEY no está definida."
[[ "${ROBLOX_UNIVERSE_ID:-}" =~ ^[0-9]+$ ]] || fail "ROBLOX_UNIVERSE_ID falta o no es numérico."
[[ "${ROBLOX_PLACE_ID:-}" =~ ^[0-9]+$ ]] || fail "ROBLOX_PLACE_ID falta o no es numérico."
[[ "$version_type" == "Published" || "$version_type" == "Saved" ]] ||
	fail "ROBLOX_VERSION_TYPE debe ser Published o Saved."
[[ -f "$place_file" ]] || fail "No existe el archivo '$place_file'."

case "$place_file" in
*.rbxlx) content_type="application/xml" ;;
*.rbxl) content_type="application/octet-stream" ;;
*) fail "Extensión no soportada: '$place_file' (usa .rbxlx o .rbxl)." ;;
esac

url="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=${version_type}"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

echo "Publicando '$place_file' ($(wc -c <"$place_file") bytes) como versión '$version_type'..."

# La cabecera con la API key se lee desde un descriptor de fichero (-H @...)
# para que no aparezca en la línea de comandos del proceso ni en los logs.
http_status="$(
	curl --silent --show-error \
		--request POST \
		--header @<(printf 'x-api-key: %s\n' "$ROBLOX_API_KEY") \
		--header "Content-Type: ${content_type}" \
		--data-binary "@${place_file}" \
		--output "$response_file" \
		--write-out '%{http_code}' \
		"$url"
)"

if [[ "$http_status" != "200" ]]; then
	echo "Respuesta de Roblox:" >&2
	cat "$response_file" >&2
	echo >&2
	fail "La publicación falló con HTTP ${http_status}."
fi

version_number="$(jq -r '.versionNumber // empty' "$response_file")"
[[ -n "$version_number" ]] || fail "Respuesta inesperada de Roblox: $(cat "$response_file")"

echo "Place publicado correctamente. versionNumber=${version_number}"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
	{
		echo "### Roblox deploy"
		echo ""
		echo "- Place ID: \`${ROBLOX_PLACE_ID}\`"
		echo "- Versión: **${version_number}** (${version_type})"
		echo "- Commit: \`${GITHUB_SHA:-local}\`"
	} >>"$GITHUB_STEP_SUMMARY"
fi
