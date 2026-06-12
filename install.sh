#!/usr/bin/env bash
set -euo pipefail

REPO="diegofaccipieri-commits/elk-pdf-releases"
APP_NAME="ELK PDF.app"
INSTALL_DIR="/Applications"
INSTALL_PATH="${INSTALL_DIR}/${APP_NAME}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

log() {
  printf '%s\n' "$1"
}

fail() {
  printf 'ERRO: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "comando ausente: $1"
}

require_command curl
require_command tar
require_command python3

LATEST_API="https://api.github.com/repos/${REPO}/releases/latest"

log "Buscando ultima versao do ELK PDF..."
RELEASE_JSON="$(curl -fsSL "${LATEST_API}")"

VERSION="$(printf '%s' "${RELEASE_JSON}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
DOWNLOAD_URL="$(printf '%s' "${RELEASE_JSON}" | python3 -c 'import json,sys
release=json.load(sys.stdin)
for asset in release["assets"]:
    if asset["name"] == "ELK.PDF.app.tar.gz":
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit("asset ELK.PDF.app.tar.gz nao encontrado")')"

ARCHIVE="${TMP_DIR}/ELK.PDF.app.tar.gz"

log "Baixando ${VERSION}..."
curl -fL --progress-bar -o "${ARCHIVE}" "${DOWNLOAD_URL}"

log "Extraindo app..."
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

test -d "${TMP_DIR}/${APP_NAME}" || fail "arquivo extraido nao contem ${APP_NAME}"

log "Instalando em ${INSTALL_PATH}..."
if [ -d "${INSTALL_PATH}" ]; then
  sudo rm -rf "${INSTALL_PATH}"
fi

sudo ditto "${TMP_DIR}/${APP_NAME}" "${INSTALL_PATH}"
sudo xattr -cr "${INSTALL_PATH}" || true

log "Abrindo ELK PDF..."
open "${INSTALL_PATH}"

log "ELK PDF ${VERSION} instalado."
