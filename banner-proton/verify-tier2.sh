#!/bin/bash
# Re-derive tier 2 of the wine branch from GE-Proton's own script and compare it with the branch.
# Checks out the tier 1 tag (Valve wine bleeding-edge) in a scratch worktree, runs the unmodified
# "(2) WINE PATCHING" section of patches/protonprep-valve-staging.sh, and diffs against bp-*-tier2.
set -euo pipefail
cd "$(dirname "$0")/.."
. banner-proton/PINS
read -r T1 T2 _ <<< "$WINE_TIER_TAGS"

WORK=$(mktemp -d)
git -C wine fetch -q origin "refs/tags/$T1:refs/tags/$T1" "refs/tags/$T2:refs/tags/$T2"
test "$(git -C wine rev-parse "$T1^{commit}")" = "$VALVE_WINE_COMMIT"
git -C wine worktree add -q --detach "$WORK/wine" "$T1"

# GE's script runs from the proton-ge-custom root: ../patches, ../wine-staging, ../wineopenxr.
ln -s "$PWD/patches" "$WORK/patches"
ln -s "$PWD/wine-staging" "$WORK/wine-staging"
cp -a wineopenxr "$WORK/wineopenxr"
( cd "$WORK/wineopenxr" && for p in ../patches/wineopenxr/*.patch; do patch -Np1 -s < "$p"; done )

awk '/^### \(2\) WINE PATCHING ###$/,/^### END WINE PATCHING ###$/' patches/protonprep-valve-staging.sh > "$WORK/ge-wine.sh"
FAILS="$WORK/fails"; : > "$FAILS"
cat > "$WORK/run.sh" <<RUN
apply_patch() { patch -Np1 < "\$1" || echo "\$1" >> "$FAILS"; }
apply_all_in_dir() { local p; for p in "\$1"/*.patch; do apply_patch "\$p"; done; }
autoreconf() { :; }
cd "$WORK"
. "$WORK/ge-wine.sh"
RUN
bash "$WORK/run.sh" > "$WORK/log" 2>&1 || true
if [ -s "$FAILS" ]; then echo "GE patches that failed:"; cat "$FAILS"; exit 1; fi

cd "$WORK/wine"
find . -path ./.git -prune -o \( -name '*.orig' -o -name '*.rej' \) -print -delete
git rm -q --cached --ignore-unmatch configure include/config.h.in
rm -f configure include/config.h.in
git add -A
if git diff --cached --quiet "$T2" --; then
    echo "OK: GE-Proton $GE_PROTON_COMMIT wine section on $T1 reproduces $T2 exactly"
else
    echo "MISMATCH between a fresh GE run and $T2:"
    git diff --cached --stat "$T2" -- | tail -20
    exit 1
fi
