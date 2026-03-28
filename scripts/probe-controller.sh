#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
MAPPING="${2:-}"
REPO_ROOT="${0:A:h:h}"
BUILD_DIR="${REPO_ROOT}/build"
OUT_BIN="${BUILD_DIR}/sdl-guid-probe-x86"
SDL_LIB="${APP_PATH}/Contents/Frameworks/libSDL2-2.0.0.dylib"
typeset -a SDL_CFLAGS

mkdir -p "${BUILD_DIR}"

if [[ ! -f "${SDL_LIB}" ]]; then
  echo "Missing SDL library: ${SDL_LIB}" >&2
  exit 1
fi

if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2; then
  SDL_CFLAGS=(${(z)$(pkg-config --cflags sdl2)})
else
  SDL_CFLAGS=(-I/opt/homebrew/include -I/opt/homebrew/include/SDL2 -I/usr/local/include -I/usr/local/include/SDL2)
fi

clang -arch x86_64 \
  "${REPO_ROOT}/src/sdl-guid-probe.c" \
  "${SDL_CFLAGS[@]}" \
  "${SDL_LIB}" \
  -o "${OUT_BIN}"

install_name_tool -change /opt/local/lib/libSDL2-2.0.0.dylib "${SDL_LIB}" "${OUT_BIN}" 2>/dev/null || true
install_name_tool -change /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib "${SDL_LIB}" "${OUT_BIN}" 2>/dev/null || true

if [[ -n "${MAPPING}" ]]; then
  SDL_GAMECONTROLLERCONFIG="${MAPPING}" "${OUT_BIN}" 5000
else
  "${OUT_BIN}" 5000
fi
