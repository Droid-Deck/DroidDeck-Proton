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
apply "$root/patches/wine-hotfixes/pending/server-directory-users-ace.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-i386-recover-lost-wake-on-address.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-wine-files-not-readonly.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-android-storage-case-insensitive.patch"
apply "$root/patches/game-patches/dirt-telemetry-sendto-closed-socket.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-wow64-exe-preferred-base.patch"
apply "$root/patches/wine-hotfixes/pending/winebuild-arm64x-import-thunk-hotpatch.patch"
apply "$root/patches/wine-hotfixes/pending/winex11-report-ime-context-focus.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-arm64ec-process-breakpoint-rip.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-server-return-event-sync-fd-on-create.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-close-sync-handle-outside-fd-cache-mutex.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-server-reuse-closed-private-events.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-skip-xattr-queries-on-unsupported-filesystems.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-use-listed-directory-as-subdirectory-parent.patch"
apply "$root/patches/wine-hotfixes/pending/ntdll-look-up-missing-file-from-existing-parent.patch"
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
