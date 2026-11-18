#!/usr/bin/env bash
set -euo pipefail
if out=$(gh release view "$1" -R "$GITHUB_REPOSITORY" --json isDraft,isPrerelease -q '"\(.isDraft) \(.isPrerelease)"' 2>&1); then
  case "$out" in
    "true "*) echo draft ;;
    "false true") echo prerelease ;;
    "false false") echo stable ;;
    *) echo "$out" >&2; exit 1 ;;
  esac
elif [ "$out" = "release not found" ]; then
  echo none
else
  echo "$out" >&2
  exit 1
fi
