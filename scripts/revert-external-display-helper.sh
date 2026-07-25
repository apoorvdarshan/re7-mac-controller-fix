#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
CONTENTS_DIR="${APP_PATH}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
FRAMEWORKS_DIR="${CONTENTS_DIR}/Frameworks"
RESOURCES_DIR="${CONTENTS_DIR}/Resources/re7-mac-controller-fix"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
TARGET_FILE="${RESOURCES_DIR}/external-display-original-executable"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "Missing original executable record: ${TARGET_FILE}" >&2
  exit 1
fi

ORIGINAL_EXECUTABLE="$(<"${TARGET_FILE}")"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${ORIGINAL_EXECUTABLE}" "${INFO_PLIST}"

rm -f \
  "${MACOS_DIR}/re7-display-launcher" \
  "${FRAMEWORKS_DIR}/re7-external-display.dylib"

plutil -lint "${INFO_PLIST}" >/dev/null
"${LSREGISTER}" -f "${APP_PATH}"

echo "Reverted game-only external display helper: ${APP_PATH}"
echo "Restored executable: ${ORIGINAL_EXECUTABLE}"
