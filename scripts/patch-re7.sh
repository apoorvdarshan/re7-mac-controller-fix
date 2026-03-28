#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
DEFAULT_MAPPING='050000695e040000e002000000696d00,Controller,a:b0,b:b1,back:b9,dpdown:b12,dpleft:b13,dpright:b14,dpup:b11,guide:b10,leftshoulder:b4,leftstick:b6,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b7,righttrigger:a5,rightx:a3,righty:a4,start:b8,x:b2,y:b3,'
MAPPING="${2:-${DEFAULT_MAPPING}}"

REPO_ROOT="${0:A:h:h}"
CONTENTS_DIR="${APP_PATH}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources/re7-mac-controller-fix"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
SDL_LIB="${CONTENTS_DIR}/Frameworks/libSDL2-2.0.0.dylib"
TARGET_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${INFO_PLIST}")"
WARMUP_BIN="${MACOS_DIR}/sdl-warmup-x86"
LAUNCHER_ENV="${MACOS_DIR}/launcher-env"
TARGET_FILE="${RESOURCES_DIR}/original-executable"
typeset -a SDL_CFLAGS

mkdir -p "${RESOURCES_DIR}"

if [[ ! -f "${SDL_LIB}" ]]; then
  echo "Missing SDL library: ${SDL_LIB}" >&2
  exit 1
fi

if [[ "${TARGET_EXECUTABLE}" == "launcher-env" && -f "${TARGET_FILE}" ]]; then
  TARGET_EXECUTABLE="$(<"${TARGET_FILE}")"
fi

if [[ "${TARGET_EXECUTABLE}" == "launcher-env" ]]; then
  if [[ -e "${MACOS_DIR}/launcher" ]]; then
    TARGET_EXECUTABLE="launcher"
  else
    TARGET_EXECUTABLE="Sikarugir"
  fi
fi

if [[ ! -f "${TARGET_FILE}" || "$(<"${TARGET_FILE}")" == "launcher-env" ]]; then
  printf '%s\n' "${TARGET_EXECUTABLE}" > "${TARGET_FILE}"
fi

if [[ ! -f "${RESOURCES_DIR}/Info.plist.original" ]]; then
  cp "${INFO_PLIST}" "${RESOURCES_DIR}/Info.plist.original"
fi

if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2; then
  SDL_CFLAGS=(${(z)$(pkg-config --cflags sdl2)})
else
  SDL_CFLAGS=(-I/opt/homebrew/include -I/opt/homebrew/include/SDL2 -I/usr/local/include -I/usr/local/include/SDL2)
fi

clang -arch x86_64 \
  "${REPO_ROOT}/src/sdl-warmup.c" \
  "${SDL_CFLAGS[@]}" \
  "${SDL_LIB}" \
  -o "${WARMUP_BIN}"

install_name_tool -change /opt/local/lib/libSDL2-2.0.0.dylib "${SDL_LIB}" "${WARMUP_BIN}" 2>/dev/null || true
install_name_tool -change /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib "${SDL_LIB}" "${WARMUP_BIN}" 2>/dev/null || true

sed \
  -e "s|__SDL_GAMECONTROLLERCONFIG__|${MAPPING//|/\\|}|g" \
  -e "s|__TARGET_EXECUTABLE__|${TARGET_EXECUTABLE}|g" \
  "${REPO_ROOT}/templates/launcher-env.zsh" > "${LAUNCHER_ENV}"

chmod +x "${LAUNCHER_ENV}" "${WARMUP_BIN}"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable launcher-env' "${INFO_PLIST}"

codesign --force --deep --sign - "${APP_PATH}" >/dev/null 2>&1 || true

echo "Patched: ${APP_PATH}"
echo "Original executable: ${TARGET_EXECUTABLE}"
echo "SDL mapping: ${MAPPING}"
