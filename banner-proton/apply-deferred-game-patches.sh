#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/wine"
apply() {
  local p=$1
  echo "deferred game patch: $(basename "$p")"
  patch -Np1 --forward < "$p"
}
apply "$root/patches/game-patches/wow-forever-arm64ec-ntdll.patch"
apply "$root/patches/wine-hotfixes/pending/server-android-shared-storage-owner.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-i386-recover-lost-wake-on-address.patch"
