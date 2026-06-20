#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-daohe-community}"
INSTALL_DIR="${INSTALL_DIR:-/opt/daohe-community}"
PACKAGE_URL="${PACKAGE_URL:-https://github.com/YuWan-030/DaoheCommunityPanel/releases/latest/download/daohe-community-linux-x64.tar.gz}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root, for example:"
  echo "  sudo su -c \"wget -qO- https://your-domain/setup.sh | bash\""
  exit 1
fi

install_with_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    yum install -y "$@"
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache "$@"
  else
    echo "No supported package manager found. Please install required tools manually: $*"
    exit 1
  fi
}

ensure_tools() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  command -v tar >/dev/null 2>&1 || missing+=("tar")
  command -v systemctl >/dev/null 2>&1 || missing+=("systemd")
  if [ "${#missing[@]}" -gt 0 ]; then
    install_with_package_manager "${missing[@]}"
  fi
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    local major
    major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
    if [ "${major}" -ge 18 ]; then
      return
    fi
  fi

  echo "Installing Node.js 20..."
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
  elif command -v dnf >/dev/null 2>&1; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs
  elif command -v yum >/dev/null 2>&1; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    yum install -y nodejs
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache nodejs npm
  else
    echo "Unable to install Node.js automatically. Please install Node.js 18+ manually."
    exit 1
  fi
}

ensure_tools
ensure_node

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Downloading package: ${PACKAGE_URL}"
curl -fL "${PACKAGE_URL}" -o "${TMP_DIR}/daohe-community-linux-x64.tar.gz"

mkdir -p "${TMP_DIR}/package"
tar -xzf "${TMP_DIR}/daohe-community-linux-x64.tar.gz" -C "${TMP_DIR}/package"

cd "${TMP_DIR}/package"
APP_NAME="${APP_NAME}" INSTALL_DIR="${INSTALL_DIR}" bash prod-scripts/linux/install-systemd.sh
