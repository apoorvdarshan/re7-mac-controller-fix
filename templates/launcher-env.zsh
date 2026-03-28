#!/bin/zsh
set -euo pipefail

SELF_DIR="${0:A:h}"
CONTENTS_DIR="${SELF_DIR:h}"

export DYLD_LIBRARY_PATH="${CONTENTS_DIR}/Frameworks:${CONTENTS_DIR}/SharedSupport/wine/lib${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}"
export SDL_JOYSTICK_HIDAPI=1
export SDL_JOYSTICK_HIDAPI_XBOX_360=1
export SDL_JOYSTICK_MFI=1
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export SDL_GAMECONTROLLERCONFIG='__SDL_GAMECONTROLLERCONFIG__'

WARMUP_LOG="/tmp/re7-controller-warmup.log"
if [[ -x "${SELF_DIR}/sdl-warmup-x86" ]]; then
  "${SELF_DIR}/sdl-warmup-x86" 5000 >"${WARMUP_LOG}" 2>&1 || true
fi

exec "${SELF_DIR}/__TARGET_EXECUTABLE__" "$@"

