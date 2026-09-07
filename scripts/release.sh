#!/usr/bin/env bash
# =============================================================
# release.sh — Automate the A Day release process.
#
# Usage:
#   ./scripts/release.sh major      # 1.1.0 → 2.0.0
#   ./scripts/release.sh minor      # 1.1.0 → 1.2.0
#   ./scripts/release.sh patch      # 1.1.0 → 1.1.1
#   ./scripts/release.sh build      # build 1 → 2  (no tag, no CI)
#   ./scripts/release.sh patch --dry-run
#
# Flow (major/minor/patch):
#   read version → bump → update CHANGELOG → update xcconfig
#   → commit → push main → tag vX.Y.Z → push tag → CI builds
#
# Flow (build):
#   same, but no tag is created and CI is not triggered.
#   Use this for TestFlight re-uploads under the same marketing version.
# =============================================================
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Paths ─────────────────────────────────────────────────────
XCCONFIG="Config/Version.xcconfig"
CHANGELOG="CHANGELOG.md"

# ── Parse arguments ───────────────────────────────────────────
BUMP_TYPE="${1:-}"
DRY_RUN=false

for arg in "${@:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo -e "${RED}❌ Unknown flag: ${arg}${RESET}" >&2; exit 1 ;;
  esac
done

if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch|build)$ ]]; then
  echo -e "${BOLD}Usage:${RESET} $(basename "$0") [major|minor|patch|build] [--dry-run]"
  echo ""
  echo "  major   1.1.0 → 2.0.0   build resets to 1 · pushes tag → CI"
  echo "  minor   1.1.0 → 1.2.0   build resets to 1 · pushes tag → CI"
  echo "  patch   1.1.0 → 1.1.1   build resets to 1 · pushes tag → CI"
  echo "  build   build 1 → 2     no tag · no CI  (TestFlight re-upload)"
  exit 1
fi

# ── Ensure we run from repo root regardless of cwd ────────────
cd "$(git rev-parse --show-toplevel)"

# ─────────────────────────────────────────────
# GUARDRAILS
# ─────────────────────────────────────────────

# Must be on main
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo -e "${RED}❌ Must be on ${BOLD}main${RESET}${RED} to cut a release.${RESET}"
  echo -e "   Current branch: ${YELLOW}${CURRENT_BRANCH}${RESET}"
  echo -e "   Merge your feature branch to main first, then re-run this script."
  exit 1
fi

# Clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo -e "${RED}❌ Working tree has uncommitted changes. Commit or stash them first.${RESET}"
  exit 1
fi

# In sync with origin/main
echo -e "${BLUE}🔄 Fetching origin/main...${RESET}"
git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [[ "$LOCAL" != "$REMOTE" ]]; then
  echo -e "${RED}❌ Local main is out of sync with origin/main.${RESET}"
  echo -e "   Run: ${YELLOW}git pull${RESET}"
  exit 1
fi

# ─────────────────────────────────────────────
# READ + COMPUTE VERSION
# ─────────────────────────────────────────────

CURRENT_MARKETING=$(grep '^MARKETING_VERSION' "$XCCONFIG" \
  | awk -F'=' '{print $2}' | tr -d ' ')
CURRENT_BUILD=$(grep '^CURRENT_PROJECT_VERSION' "$XCCONFIG" \
  | awk -F'=' '{print $2}' | tr -d ' ')

IFS='.' read -r V_MAJOR V_MINOR V_PATCH <<< "$CURRENT_MARKETING"

case "$BUMP_TYPE" in
  major) NEW_MARKETING="$((V_MAJOR + 1)).0.0";                   NEW_BUILD=1 ;;
  minor) NEW_MARKETING="${V_MAJOR}.$((V_MINOR + 1)).0";          NEW_BUILD=1 ;;
  patch) NEW_MARKETING="${V_MAJOR}.${V_MINOR}.$((V_PATCH + 1))"; NEW_BUILD=1 ;;
  build) NEW_MARKETING="$CURRENT_MARKETING";                     NEW_BUILD=$((CURRENT_BUILD + 1)) ;;
esac

# ─────────────────────────────────────────────
# SUMMARY + CONFIRM
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}Release Summary${RESET}"
echo -e "  Bump type : ${YELLOW}${BUMP_TYPE}${RESET}"
echo -e "  Version   : ${CURRENT_MARKETING} (build ${CURRENT_BUILD})  →  ${GREEN}${BOLD}${NEW_MARKETING} (build ${NEW_BUILD})${RESET}"
if [[ "$BUMP_TYPE" != "build" ]]; then
  echo -e "  Git tag   : ${GREEN}v${NEW_MARKETING}${RESET} will be pushed → CI builds + publishes GitHub Release"
else
  echo -e "  Git tag   : ${YELLOW}none${RESET} — build bump does not trigger CI"
fi
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}🏜  Dry run — no changes made.${RESET}"
  exit 0
fi

read -r -p "$(echo -e "${BOLD}Proceed?${RESET} [y/N] ")" CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
echo ""

# ─────────────────────────────────────────────
# CHANGELOG
# ─────────────────────────────────────────────

# Collect commits since the last tag (or all commits if no tag yet)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)

if [[ -n "$LAST_TAG" ]]; then
  RAW_LOG=$(git log --oneline --no-merges "${LAST_TAG}..HEAD" 2>/dev/null || true)
else
  RAW_LOG=$(git log --oneline --no-merges 2>/dev/null || true)
fi

if [[ -n "$RAW_LOG" ]]; then
  # Strip the short SHA, format each line as a bullet
  COMMIT_LIST=$(echo "$RAW_LOG" | sed 's/^[a-f0-9]\{7,\} /- /')
else
  COMMIT_LIST="- no commits since last release"
fi

TODAY=$(date +%Y-%m-%d)

if [[ "$BUMP_TYPE" == "build" ]]; then
  ENTRY_HEADER="## [${NEW_MARKETING}] Build ${NEW_BUILD} — ${TODAY}"
else
  ENTRY_HEADER="## [${NEW_MARKETING}] — ${TODAY}"
fi

TEMP_LOG=$(mktemp)

if [[ -f "$CHANGELOG" ]]; then
  # Insert the new entry just before the first existing ## section
  FIRST_SECTION=$(grep -n '^## ' "$CHANGELOG" | head -1 | cut -d: -f1)
  if [[ -n "$FIRST_SECTION" ]]; then
    LINE_BEFORE=$((FIRST_SECTION - 1))
    {
      head -n "$LINE_BEFORE" "$CHANGELOG"
      echo ""
      echo "$ENTRY_HEADER"
      echo ""
      echo "$COMMIT_LIST"
      echo ""
      tail -n "+${FIRST_SECTION}" "$CHANGELOG"
    } > "$TEMP_LOG"
  else
    {
      cat "$CHANGELOG"
      echo ""
      echo "$ENTRY_HEADER"
      echo ""
      echo "$COMMIT_LIST"
      echo ""
    } > "$TEMP_LOG"
  fi
else
  # First-time creation
  {
    echo "# Changelog"
    echo ""
    echo "All notable changes to this project will be documented in this file."
    echo ""
    echo "$ENTRY_HEADER"
    echo ""
    echo "$COMMIT_LIST"
    echo ""
  } > "$TEMP_LOG"
fi

mv "$TEMP_LOG" "$CHANGELOG"
echo -e "📝 Updated ${CHANGELOG}"

# ─────────────────────────────────────────────
# VERSION.XCCONFIG
# ─────────────────────────────────────────────

sed -i '' "s/^MARKETING_VERSION = .*/MARKETING_VERSION = ${NEW_MARKETING}/" "$XCCONFIG"
sed -i '' "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = ${NEW_BUILD}/" "$XCCONFIG"
echo -e "📦 Updated ${XCCONFIG}"

# ─────────────────────────────────────────────
# COMMIT
# ─────────────────────────────────────────────

if [[ "$BUMP_TYPE" == "build" ]]; then
  COMMIT_MSG="chore: bump build to ${NEW_MARKETING} build ${NEW_BUILD}"
else
  COMMIT_MSG="chore: bump version to ${NEW_MARKETING}"
fi

git add "$XCCONFIG" "$CHANGELOG"
git commit -m "$COMMIT_MSG"
echo -e "📌 Committed: ${COMMIT_MSG}"

# ─────────────────────────────────────────────
# PUSH MAIN
# ─────────────────────────────────────────────

echo -e "\n${BLUE}🚀 Pushing to main...${RESET}"
git push origin main

# ─────────────────────────────────────────────
# TAG + PUSH (version bumps only)
# ─────────────────────────────────────────────

if [[ "$BUMP_TYPE" != "build" ]]; then
  TAG="v${NEW_MARKETING}"
  git tag -a "$TAG" -m "Release ${NEW_MARKETING}"
  git push origin "$TAG"
  echo -e "${GREEN}🏷  Tagged ${TAG} and pushed — CI will now build and publish the GitHub Release.${RESET}"
else
  echo -e "${GREEN}✅ Build ${NEW_BUILD} is on main. No tag created — CI not triggered.${RESET}"
  echo -e "   Monitor TestFlight for the manual upload if needed."
fi

echo -e "\n${GREEN}${BOLD}🎉 ${NEW_MARKETING} (build ${NEW_BUILD}) released successfully!${RESET}\n"
