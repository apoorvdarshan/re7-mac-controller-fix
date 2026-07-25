#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
CONTENTS_DIR="${APP_PATH}/Contents"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
RESOURCES_DIR="${CONTENTS_DIR}/Resources/re7-mac-controller-fix"
BACKUP_PLIST="${RESOURCES_DIR}/Info.plist.before-fresh-install-fix"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

FRESH_INSTALL_MAPPING='030080805e0400008e02000010016800,Controller,a:b0,b:b1,back:b4,dpdown:b12,dpleft:b13,dpright:b14,dpup:b11,guide:b5,leftshoulder:b9,leftstick:b7,lefttrigger:a4,leftx:a0,lefty:a1~,rightshoulder:b10,rightstick:b8,righttrigger:a5,rightx:a2,righty:a3~,start:b6,x:b2,y:b3,'

if [[ ! -f "${INFO_PLIST}" ]]; then
  echo "Missing app Info.plist: ${INFO_PLIST}" >&2
  exit 1
fi

set_plist_string() {
  local key="$1"
  local value="$2"

  if /usr/libexec/PlistBuddy -c "Print :${key}" "${INFO_PLIST}" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "${INFO_PLIST}"
  else
    /usr/libexec/PlistBuddy -c "Add :${key} string ${value}" "${INFO_PLIST}"
  fi
}

mkdir -p "${RESOURCES_DIR}"
if [[ ! -f "${BACKUP_PLIST}" ]]; then
  cp -p "${INFO_PLIST}" "${BACKUP_PLIST}"
fi

if ! /usr/libexec/PlistBuddy -c "Print :LSEnvironment" "${INFO_PLIST}" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :LSEnvironment dict" "${INFO_PLIST}"
fi

set_plist_string "LSEnvironment:SDL_GAMECONTROLLERCONFIG" "${FRESH_INSTALL_MAPPING}"
set_plist_string "LSEnvironment:SDL_JOYSTICK_HIDAPI" "1"
set_plist_string "LSEnvironment:SDL_JOYSTICK_HIDAPI_XBOX_360" "1"
set_plist_string "LSEnvironment:SDL_JOYSTICK_MFI" "1"
set_plist_string "LSEnvironment:SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS" "1"

plutil -lint "${INFO_PLIST}" >/dev/null
"${LSREGISTER}" -f "${APP_PATH}"

echo "Applied persistent fresh-install controller fix: ${APP_PATH}"
echo "Controller GUID: 030080805e0400008e02000010016800"
echo "Vertical axes: lefty:a1~ righty:a3~"
echo "Quit any running Wine processes, then launch the app normally."
