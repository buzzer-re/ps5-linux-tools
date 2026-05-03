#!/usr/bin/env bash

set -euo pipefail

BINARY_NAME="ps5_control"
INSTALL_BIN="/usr/local/sbin/${BINARY_NAME}"
SYSTEMD_DIR="/etc/systemd/system"

usage() {
    cat <<EOF
Usage: sudo $0

Installs:
  ${INSTALL_BIN}
  ${SYSTEMD_DIR}/ps5fan.service
  ${SYSTEMD_DIR}/ps5boost.service

Both services are enabled and started by default. Disable either one with:
  sudo systemctl disable --now ps5fan.service
  sudo systemctl disable --now ps5boost.service
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "This installer does not accept options: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [[ ${EUID} -ne 0 ]]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl not found; this installer requires systemd." >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "Building ${BINARY_NAME}..."
make "${BINARY_NAME}"

echo "Installing ${INSTALL_BIN}..."
install -Dm755 "${BINARY_NAME}" "${INSTALL_BIN}"

echo "Installing systemd units..."
install -Dm644 systemd/ps5fan.service "${SYSTEMD_DIR}/ps5fan.service"
install -Dm644 systemd/ps5boost.service "${SYSTEMD_DIR}/ps5boost.service"

systemctl daemon-reload

echo "Enabling and starting ps5fan.service and ps5boost.service..."
systemctl enable --now ps5fan.service ps5boost.service

echo "Done."
echo "Disable services you do not want:"
echo "  sudo systemctl disable --now ps5fan.service"
echo "  sudo systemctl disable --now ps5boost.service"
