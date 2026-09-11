#!/bin/sh
# =============================================================
# ci_post_clone.sh — Xcode Cloud post-clone hook.
#
# Xcode Cloud runs this automatically right after it checks out the
# repo, before resolving packages or building. It runs with the
# repo root as the working directory.
#
# What it does:
#   Stamps CURRENT_PROJECT_VERSION in Config/Version.xcconfig with
#   Xcode Cloud's own monotonic build counter ($CI_BUILD_NUMBER), so
#   every TestFlight upload of "A Day (Beta)" gets a unique, always-
#   increasing build number without anyone committing a bump.
#
#   MARKETING_VERSION (→ CFBundleShortVersionString) is left alone —
#   it stays the human-chosen SemVer from Config/Version.xcconfig
#   (see VERSIONING.md). Only the build number is machine-managed.
#
# This edit happens on the CI checkout only. It is never committed
# and never touches a developer's working tree.
#
# Outside Xcode Cloud ($CI_BUILD_NUMBER unset) this is a no-op, so
# the script is safe to run locally.
# =============================================================
set -eu

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "ci_post_clone: CI_BUILD_NUMBER not set — not running in Xcode Cloud, skipping."
  exit 0
fi

# Xcode Cloud checks the scripts out under ci_scripts/; the repo root
# is one level up and is also the working directory Xcode Cloud uses.
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
XCCONFIG="$REPO_ROOT/Config/Version.xcconfig"

if [ ! -f "$XCCONFIG" ]; then
  echo "ci_post_clone: $XCCONFIG not found" >&2
  exit 1
fi

echo "ci_post_clone: stamping CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER in Config/Version.xcconfig"
/usr/bin/sed -i '' \
  "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER}/" \
  "$XCCONFIG"

echo "ci_post_clone: Config/Version.xcconfig is now:"
/bin/cat "$XCCONFIG"
