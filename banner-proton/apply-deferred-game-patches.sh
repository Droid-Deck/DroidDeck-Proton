#!/bin/bash
# Apply game-patches not yet baked into the pinned wine submodule tier tags.
# Not listed in patches/protonprep-valve-staging.sh (verify-tier2 must match bp-*-tier2).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/wine"
apply() {
  local p=$1
  echo "deferred game patch: $(basename "$p")"
  patch -Np1 --forward < "$p"
}
apply "$root/patches/game-patches/wow-forever-arm64ec-ntdll.patch"
