#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-daohe-community}"
INSTALL_DIR="${INSTALL_DIR:-/opt/daohe-community}"
SERVICE_USER="${SERVICE_USER:-root}"
NODE_BIN="${NODE_BIN:-$(command -v node || true)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root, for example: sudo bash prod-scripts/linux/install-systemd.sh"
  exit 1
fi

if [ -z "${NODE_BIN}" ]; then
  echo "Node.js was not found. Please install Node.js 18+ first."
  exit 1
fi

if [ ! -f "${SOURCE_DIR}/web/app.js" ] || [ ! -f "${SOURCE_DIR}/daemon/app.js" ]; then
  echo "This script must be run from a built production-code package."
  echo "Expected files: web/app.js and daemon/app.js"
  exit 1
fi

echo "Installing ${APP_NAME} to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"

copy_component() {
  local name="$1"
  local source="${SOURCE_DIR}/${name}"
  local target="${INSTALL_DIR}/${name}"

  if [ "$(realpath -m "${source}")" = "$(realpath -m "${target}")" ]; then
    return
  fi

  local backup
  backup="$(mktemp -d)"
  if [ -d "${target}/data" ]; then cp -a "${target}/data" "${backup}/data"; fi
  if [ -d "${target}/logs" ]; then cp -a "${target}/logs" "${backup}/logs"; fi
  if [ "${name}" = "web" ] && [ -d "${target}/public/upload_files" ]; then
    mkdir -p "${backup}/public"
    cp -a "${target}/public/upload_files" "${backup}/public/upload_files"
  fi

  rm -rf "${target}"
  mkdir -p "$(dirname "${target}")"
  cp -a "${source}" "${target}"

  if [ -d "${backup}/data" ]; then rm -rf "${target}/data"; cp -a "${backup}/data" "${target}/data"; fi
  if [ -d "${backup}/logs" ]; then rm -rf "${target}/logs"; cp -a "${backup}/logs" "${target}/logs"; fi
  if [ -d "${backup}/public/upload_files" ]; then
    mkdir -p "${target}/public"
    rm -rf "${target}/public/upload_files"
    cp -a "${backup}/public/upload_files" "${target}/public/upload_files"
  fi
  rm -rf "${backup}"
}

copy_component web
copy_component daemon
copy_component prod-scripts

echo "Installing production npm dependencies..."
npm --prefix "${INSTALL_DIR}/web" install --production --no-fund --no-audit
npm --prefix "${INSTALL_DIR}/daemon" install --production --no-fund --no-audit

echo "Installing daemon binary dependencies..."
mkdir -p "${INSTALL_DIR}/daemon/lib"
download_if_missing() {
  local url="$1"
  local out="${INSTALL_DIR}/daemon/lib/$(basename "${url}")"
  if [ ! -f "${out}" ]; then
    curl -fL "${url}" -o "${out}"
  fi
}

download_if_missing "https://github.com/MCSManager/PTY/releases/download/latest/pty_linux_x64"
download_if_missing "https://github.com/MCSManager/Zip-Tools/releases/download/latest/file_zip_linux_x64"
download_if_missing "https://github.com/MCSManager/Zip-Tools/releases/download/latest/7z_linux_x64"
chmod +x "${INSTALL_DIR}/daemon/lib/"*

cat > "/etc/systemd/system/${APP_NAME}-daemon.service" <<EOF
[Unit]
Description=Daohe Community Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}/daemon
ExecStart=${NODE_BIN} --max-old-space-size=8192 --enable-source-maps ${INSTALL_DIR}/daemon/app.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

cat > "/etc/systemd/system/${APP_NAME}-web.service" <<EOF
[Unit]
Description=Daohe Community Web Panel
After=network-online.target ${APP_NAME}-daemon.service
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}/web
ExecStart=${NODE_BIN} --max-old-space-size=8192 --enable-source-maps ${INSTALL_DIR}/web/app.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${APP_NAME}-daemon.service"
systemctl enable --now "${APP_NAME}-web.service"

echo "------------"
echo "Installed successfully."
echo "Web service:    ${APP_NAME}-web.service"
echo "Daemon service: ${APP_NAME}-daemon.service"
echo "Panel URL:      http://<server-ip>:23333"
echo ""
echo "Useful commands:"
echo "  systemctl status ${APP_NAME}-web ${APP_NAME}-daemon"
echo "  journalctl -u ${APP_NAME}-web -f"
echo "  journalctl -u ${APP_NAME}-daemon -f"
echo "------------"
