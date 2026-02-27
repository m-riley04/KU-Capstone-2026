#!/bin/bash
set -euo pipefail

: "${POLYPOD_USER:=pod}"

FLUTTER_DIR="/opt/flutter"
PROFILE_D="/etc/profile.d/flutter.sh"

echo "[flutter-init] Installing Flutter into ${FLUTTER_DIR}"

if [[ ! -d "${FLUTTER_DIR}/.git" ]]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
else
  echo "[flutter-init] Flutter already present; skipping clone."
fi

chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "${FLUTTER_DIR}"

if [[ ! -f "${PROFILE_D}" ]] || ! grep -q "FLUTTER_HOME" "${PROFILE_D}"; then
  cat > "${PROFILE_D}" <<'EOF'
export FLUTTER_HOME=/opt/flutter
export PATH="$PATH:$FLUTTER_HOME/bin"
EOF
  chmod 0644 "${PROFILE_D}"
fi

echo "[flutter-init] Running flutter doctor as ${POLYPOD_USER} (non-root)."
su - "${POLYPOD_USER}" -c '
  set -e
  export FLUTTER_HOME=/opt/flutter
  export PATH="$PATH:$FLUTTER_HOME/bin"
  flutter --version
  flutter config --enable-linux-desktop
  flutter doctor
'