#!/bin/zsh
set -euo pipefail

SELF_DIR="${0:A:h}"
CONTENTS_DIR="${SELF_DIR:h}"
CONFIG_PATH="${CONTENTS_DIR}/SharedSupport/prefix/drive_c/ToxicGame/RESIDENT-EVIL-7/RESIDENT EVIL 7 biohazard/re7_config.ini"
DISPLAY_LOG="/tmp/re7-display-mode.log"

choose_fullscreen_mode() {
  [[ -f "${CONFIG_PATH}" ]] || return 0

  /usr/sbin/system_profiler -json SPDisplaysDataType > /tmp/re7-spdisplays.json 2>/dev/null || return 0

  /usr/bin/python3 - "${CONFIG_PATH}" "${DISPLAY_LOG}" <<'PY' || true
import json
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
log_path = Path(sys.argv[2])
sp_path = Path("/tmp/re7-spdisplays.json")

def log(msg: str) -> None:
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(msg + "\n")

try:
    sp = json.loads(sp_path.read_text(encoding="utf-8"))
except Exception as exc:
    log(f"display-mode: failed to read display info: {exc}")
    raise SystemExit(0)

target_w = None
target_h = None
for gpu in sp.get("SPDisplaysDataType", []):
    displays = gpu.get("spdisplays_ndrvs", [])
    main = next((d for d in displays if d.get("spdisplays_main") == "spdisplays_yes"), None)
    chosen = main or next((d for d in displays if d.get("spdisplays_online") == "spdisplays_yes"), None)
    if not chosen:
        continue
    res = chosen.get("_spdisplays_resolution") or chosen.get("_spdisplays_pixels") or ""
    match = re.search(r"(\d+)\s*x\s*(\d+)", res)
    if match:
        target_w = int(match.group(1))
        target_h = int(match.group(2))
        log(f"display-mode: target display={chosen.get('_name','unknown')} {target_w}x{target_h}")
        break

if not target_w or not target_h:
    log("display-mode: no target display resolution found")
    raise SystemExit(0)

lines = config_path.read_text(encoding="utf-8", errors="ignore").splitlines()
values = {}
for line in lines:
    if "=" in line:
        key, value = line.split("=", 1)
        values[key] = value

try:
    count = int(values.get("DisplayModeCount", "0"))
except ValueError:
    log("display-mode: invalid DisplayModeCount")
    raise SystemExit(0)

modes = []
for idx in range(count):
    width = values.get(f"DisplayMode{idx}_Width")
    height = values.get(f"DisplayMode{idx}_Height")
    if not width or not height:
        continue
    try:
        modes.append((idx, int(width), int(height)))
    except ValueError:
        continue

if not modes:
    log("display-mode: no display modes found in config")
    raise SystemExit(0)

exact = [mode for mode in modes if mode[1] == target_w and mode[2] == target_h]
if exact:
    best = exact[0]
else:
    fitting = [mode for mode in modes if mode[1] <= target_w and mode[2] <= target_h]
    if fitting:
        best = max(fitting, key=lambda mode: (mode[1] * mode[2], mode[1], mode[2]))
    else:
        best = min(
            modes,
            key=lambda mode: (abs(mode[1] - target_w) + abs(mode[2] - target_h), -(mode[1] * mode[2])),
        )

chosen_idx, chosen_w, chosen_h = best
current_idx = values.get("FullScreenDisplayMode")
log(f"display-mode: current={current_idx} chosen={chosen_idx} {chosen_w}x{chosen_h}")

updated = []
for line in lines:
    if line.startswith("FullScreenDisplayMode="):
        updated.append(f"FullScreenDisplayMode={chosen_idx}")
    else:
        updated.append(line)

config_path.write_text("\n".join(updated) + "\n", encoding="utf-8")
PY
}

export DYLD_LIBRARY_PATH="${CONTENTS_DIR}/Frameworks:${CONTENTS_DIR}/SharedSupport/wine/lib${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}"
export SDL_JOYSTICK_HIDAPI=1
export SDL_JOYSTICK_HIDAPI_XBOX_360=1
export SDL_JOYSTICK_MFI=1
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export SDL_GAMECONTROLLERCONFIG='__SDL_GAMECONTROLLERCONFIG__'

choose_fullscreen_mode

WARMUP_LOG="/tmp/re7-controller-warmup.log"
if [[ -x "${SELF_DIR}/sdl-warmup-x86" ]]; then
  "${SELF_DIR}/sdl-warmup-x86" 5000 >"${WARMUP_LOG}" 2>&1 || true
fi

exec "${SELF_DIR}/__TARGET_EXECUTABLE__" "$@"
