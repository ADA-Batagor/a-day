#!/usr/bin/env bash
# Swaps the team-default bundle/App Group identifiers (com.tudemaha.lawar) for
# a personal development suffix, so you can build with your own signing team
# without hand-editing project.pbxproj and both Info.plist files on every pull.
#
# Usage:
#   scripts/local-bundle-id.sh set <suffix>   e.g. `set gorengan`
#   scripts/local-bundle-id.sh reapply        re-apply your last-used suffix
#   scripts/local-bundle-id.sh reset          restore the team default (lawar)
#   scripts/local-bundle-id.sh status         show current + stored suffix
#
# One-time setup so this re-applies automatically after every `git pull`:
#   git config core.hooksPath .githooks
#
# macOS/BSD sed only (ships with Xcode's command line tools). If you use GNU
# sed (e.g. via Homebrew as `gsed`), swap `sed -i ''` for `gsed -i` below.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TEAM_DEFAULT="lawar"
STATE_FILE=".local-bundle-id"
PBXPROJ="batagor.xcodeproj/project.pbxproj"
APP_PLIST="batagor/Info.plist"
WIDGET_PLIST="widget/Info.plist"

current_suffix() {
  grep -o "com\.tudemaha\.[a-zA-Z0-9]*" "$APP_PLIST" | head -1 | sed 's/com\.tudemaha\.//'
}

apply_suffix() {
  local suffix="$1"
  local from
  from="$(current_suffix)"

  if [ "$from" = "$suffix" ]; then
    echo "Already set to com.tudemaha.${suffix} — nothing to do."
    return
  fi

  # project.pbxproj: PRODUCT_BUNDLE_IDENTIFIER for both targets (Debug + Release)
  sed -i '' "s/com\.tudemaha\.${from}\.widget/com.tudemaha.${suffix}.widget/g" "$PBXPROJ"
  sed -i '' "s/com\.tudemaha\.${from};/com.tudemaha.${suffix};/g" "$PBXPROJ"

  # Info.plist: MainAppBundleIdentifier + GroupAppBundleIdentifier (both targets)
  for plist in "$APP_PLIST" "$WIDGET_PLIST"; do
    sed -i '' "s/group\.com\.tudemaha\.${from}/group.com.tudemaha.${suffix}/g" "$plist"
    sed -i '' "s/>com\.tudemaha\.${from}</>com.tudemaha.${suffix}</g" "$plist"
  done

  echo "$suffix" > "$STATE_FILE"
  echo "Switched com.tudemaha.${from} -> com.tudemaha.${suffix}"
  echo "Remember to also set your Team in Signing & Capabilities for both targets,"
  echo "and add/select a matching App Group (group.com.tudemaha.${suffix})."
}

case "${1:-}" in
  set)
    [ -n "${2:-}" ] || { echo "Usage: $0 set <suffix>" >&2; exit 1; }
    apply_suffix "$2"
    ;;
  reset)
    apply_suffix "$TEAM_DEFAULT"
    rm -f "$STATE_FILE"
    ;;
  status)
    echo "Currently in project files: com.tudemaha.$(current_suffix)"
    if [ -f "$STATE_FILE" ]; then
      echo "Stored personal suffix:     com.tudemaha.$(cat "$STATE_FILE")"
    else
      echo "No personal suffix stored yet — run: $0 set <suffix>"
    fi
    ;;
  reapply)
    if [ -f "$STATE_FILE" ]; then
      apply_suffix "$(cat "$STATE_FILE")"
    else
      echo "No stored suffix yet — run: $0 set <suffix> once first."
    fi
    ;;
  *)
    echo "Usage: $0 {set <suffix>|reapply|reset|status}" >&2
    exit 1
    ;;
esac
