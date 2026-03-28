#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
CONTENTS_DIR="${APP_PATH}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources/re7-mac-controller-fix"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
TARGET_FILE="${RESOURCES_DIR}/original-executable"

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "Missing original executable backup: ${TARGET_FILE}" >&2
  exit 1
fi

ORIGINAL_EXECUTABLE="$(<"${TARGET_FILE}")"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${ORIGINAL_EXECUTABLE}" "${INFO_PLIST}"

rm -f "${MACOS_DIR}/launcher-env" "${MACOS_DIR}/sdl-warmup-x86"

codesign --force --deep --sign - "${APP_PATH}" >/dev/null 2>&1 || true

echo "Reverted: ${APP_PATH}"
echo "Restored executable: ${ORIGINAL_EXECUTABLE}"
