#!/bin/bash
# Re-derive tier 2 of the wine branch from GE-Proton's own script and compare it with the branch.
# Checks out the tier 1 tag (Valve wine bleeding-edge) in a scratch worktree, runs the unmodified
# "(2) WINE PATCHING" section of patches/protonprep-valve-staging.sh, and diffs against bp-*-tier2 plus
# the tier 2 follow-up commits (WINE_TIER2_FOLLOWUPS: GE wine patches added after tier 2 was made, which
# sit on top of the later tiers so that no tier commit or tag is rewritten).
set -euo pipefail
cd "$(dirname "$0")/.."
. banner-proton/PINS
read -r T1 T2 _ <<< "$WINE_TIER_TAGS"

WORK=$(mktemp -d)
FOLLOWUPS=${WINE_TIER2_FOLLOWUPS:-}
git -C wine fetch -q origin "refs/tags/$T1:refs/tags/$T1" "refs/tags/$T2:refs/tags/$T2" \
    $(for t in $FOLLOWUPS; do echo "refs/tags/$t:refs/tags/$t"; done)
test "$(git -C wine rev-parse "$T1^{commit}")" = "$VALVE_WINE_COMMIT"
git -C wine worktree add -q --detach "$WORK/wine" "$T1"

# Expected result: tier 2 with each follow-up commit's change applied, in order.
git -C wine worktree add -q --detach "$WORK/expected" "$T2"
for t in $FOLLOWUPS; do
    echo "tier 2 follow-up $t: $(git -C wine log -1 --format='%h %s' "$t^{commit}")"
    git -C wine diff --binary "$t^{commit}~1" "$t^{commit}" | git -C "$WORK/expected" apply --index
done
EXPECTED=$(git -C "$WORK/expected" write-tree)

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
echo "GE wine section output (tail):"; tail -n 15 "$WORK/log"
if [ -s "$FAILS" ]; then echo "GE patches that failed:"; cat "$FAILS"; exit 1; fi

cd "$WORK/wine"
find . -name .git -prune -o \( -name '*.orig' -o -name '*.rej' \) -print0 | xargs -0 -r rm -f
git rm -q -f --cached --ignore-unmatch configure include/config.h.in
rm -f configure include/config.h.in
git add -A
if git diff-index --cached --quiet "$EXPECTED" --; then
    echo "OK: GE-Proton $GE_PROTON_COMMIT wine section on $T1 reproduces $T2${FOLLOWUPS:+ + $FOLLOWUPS} exactly"
else
    echo "MISMATCH between a fresh GE run and $T2${FOLLOWUPS:+ + $FOLLOWUPS}:"
    git diff-index --cached --stat "$EXPECTED" -- | tail -20
    exit 1
fi
