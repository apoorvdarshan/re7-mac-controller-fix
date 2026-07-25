#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
PREFERRED_DISPLAY="VX2779 Series"
REPO_ROOT="${0:A:h:h}"
BUILD_DIR="${REPO_ROOT}/build"
CONTENTS_DIR="${APP_PATH}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
FRAMEWORKS_DIR="${CONTENTS_DIR}/Frameworks"
RESOURCES_DIR="${CONTENTS_DIR}/Resources/re7-mac-controller-fix"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
TARGET_FILE="${RESOURCES_DIR}/external-display-original-executable"
HELPER_NAME="re7-display-launcher"
HELPER_PATH="${MACOS_DIR}/${HELPER_NAME}"
DYLIB_PATH="${FRAMEWORKS_DIR}/re7-external-display.dylib"
BUILT_HELPER="${BUILD_DIR}/re7-display-launcher-x86"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [[ ! -f "${INFO_PLIST}" ]]; then
  echo "Missing app Info.plist: ${INFO_PLIST}" >&2
  exit 1
fi

CURRENT_EXECUTABLE="$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${INFO_PLIST}")"
mkdir -p "${BUILD_DIR}" "${RESOURCES_DIR}"

if [[ "${CURRENT_EXECUTABLE}" != "${HELPER_NAME}" ]]; then
  printf '%s\n' "${CURRENT_EXECUTABLE}" > "${TARGET_FILE}"
elif [[ ! -f "${TARGET_FILE}" ]]; then
  echo "Missing original executable record: ${TARGET_FILE}" >&2
  exit 1
fi

clang -arch x86_64 -O2 -fobjc-arc \
  "${REPO_ROOT}/src/re7-display-launcher.m" \
  -framework AppKit \
  -framework ApplicationServices \
  -framework CoreGraphics \
  -o "${BUILT_HELPER}"

codesign --force --sign - "${BUILT_HELPER}" >/dev/null
cp "${BUILT_HELPER}" "${HELPER_PATH}"
chmod +x "${HELPER_PATH}"
rm -f "${DYLIB_PATH}"

/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${HELPER_NAME}" "${INFO_PLIST}"

plutil -lint "${INFO_PLIST}" >/dev/null
"${LSREGISTER}" -f "${APP_PATH}"

echo "Installed game-only external display helper: ${APP_PATH}"
echo "Preferred display: ${PREFERRED_DISPLAY}"
echo "Fallback: macOS Main Display when no external display is connected"
