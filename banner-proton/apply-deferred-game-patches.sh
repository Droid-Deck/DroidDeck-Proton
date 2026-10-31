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
apply "$root/patches/wine-hotfixes/pending/ntdll-wine-files-not-readonly.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-android-storage-case-insensitive.patch"
if [ -f "$root/FEX/CMakeLists.txt" ]; then
  cd "$root/FEX"
  for p in "$root"/patches/fex/*.patch; do
    echo "FEX patch: $(basename "$p")"
    patch -Np1 --forward < "$p"
  done
  # FEX's rpmalloc is a submodule of its own, out of reach of the series above.
  for p in "$root"/patches/fex/rpmalloc/*.patch; do
    echo "FEX rpmalloc patch: $(basename "$p")"
    patch -d External/rpmalloc -Np1 --forward < "$p"
  done
fi
