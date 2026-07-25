#!/bin/zsh
set -euo pipefail

APP_PATH="${1:-/Applications/Resident Evil 7.app}"
CONTENTS_DIR="${APP_PATH}/Contents"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
BACKUP_PLIST="${CONTENTS_DIR}/Resources/re7-mac-controller-fix/Info.plist.before-fresh-install-fix"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [[ ! -f "${BACKUP_PLIST}" ]]; then
  echo "Missing fresh-install backup: ${BACKUP_PLIST}" >&2
  exit 1
fi

cp -p "${BACKUP_PLIST}" "${INFO_PLIST}"
plutil -lint "${INFO_PLIST}" >/dev/null
"${LSREGISTER}" -f "${APP_PATH}"

echo "Reverted persistent fresh-install controller fix: ${APP_PATH}"
