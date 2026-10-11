#!/bin/bash
# CI helpers for the parallel aarch64 build (.github/workflows/build-aarch64.yml, _group.yml).
# Local builds do not use this file.
#
# The build is split into groups that run as separate jobs. Each group runs the container make for
# its own targets in an empty build directory, plus the outputs of the groups it depends on. A group's
# output (stamps, dist/ files and whatever later groups need) is packed into one tarball that is kept
# in the Actions cache under a key made from the group's sources.
#
# Restored stamps are passed to make with "-o": Proton's rsync source check marks some components
# dirty even when nothing changed (autoreconf output in the synced tree, FEX's .git_describe), and
# without -o make would rebuild them, and everything after them, in a job that does not have their
# build trees.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
B=$ROOT/build
OLD_LIST=$B/bp-old-files.txt
RESTORED_LIST=$B/bp-restored.txt

cmd=${1:?command}; shift

keys() {
    cd "$ROOT"
    local img; img=$(. banner-proton/PINS; echo "$STEAMRT_IMAGE")
    # Inputs shared by every group: the build rules, the source preparation, this CI and the SDK.
    common() {
        git ls-files -s -- Makefile.in make configure.sh patches .github/patches \
            banner-proton/prep.sh banner-proton/ci.sh .github/workflows/_group.yml
        echo "$img"
    }
    key() { { common; git ls-files -s -- "$@"; } | sha256sum | cut -c1-20; }
    local graphics fex media misc wine
    graphics=$(key meson glslang Vulkan-Headers SPIRV-Headers dxvk d7vk dxvk-nvapi dxvk-igdext vkd3d-proton vklayers)
    fex=$(key FEX FEX_Config.json)
    media=$(key meson dav1d libsoup libxml2 libxkbcommon wayland-protocols libpcap graphene xz bzip2 pipewire \
        ffmpeg OpenXR-SDK piper openfst kaldi vosk-api vklayers/build-steam-overlay-wayland.mk)
    misc=$(key fonts protonfixes)
    # wine links against the media group, so its key includes the media key.
    wine=$( { echo "$media"; key wine Vulkan-Headers SPIRV-Headers vkd3d lsteamclient steam_helper vrclient_x64 \
        umu_helper openvr discord-rpc-bridge; } | sha256sum | cut -c1-20)
    printf '{"graphics":"grp-graphics-%s","fex":"grp-fex-%s","media":"grp-media-%s","misc":"grp-misc-%s","wine":"grp-wine-%s"}\n' \
        "$graphics" "$fex" "$media" "$misc" "$wine"
}

# Run the container make for the given goals, with every restored stamp marked as old (-o).
cmake_() {
    cd "$B"
    local docker_base
    docker_base=$(make -s --no-print-directory --eval='bp-docker-base: ; @echo $(DOCKER_BASE)' bp-docker-base)
    mkdir -p "$CCACHE_DIR" "${CARGO_HOME:-$HOME/.cargo}"
    local olds=()
    if [ -f "$OLD_LIST" ]; then
        while IFS= read -r f; do olds+=(-o "$f"); done < <(sort -u "$OLD_LIST")
    fi
    echo "make goals: $*"
    echo "stamps kept as old: $(( ${#olds[@]} / 2 ))"
    # shellcheck disable=SC2086
    $docker_base make -j"$(nproc)" -f Makefile CONTAINER=1 "${olds[@]}" "$@"
}

# Pack the build directory, minus build trees and minus what was restored from other groups.
pack() {
    local out=$1 exclude=$2 keep=${3:-'^$'}
    cd "$B"
    find . -mindepth 1 -printf '%P\n' | LC_ALL=C sort > /tmp/bp-all.txt
    { grep -Ev "$exclude" /tmp/bp-all.txt || true; grep -E "$keep" /tmp/bp-all.txt || true; } | LC_ALL=C sort -u > /tmp/bp-pack.txt
    if [ -f "$RESTORED_LIST" ]; then
        LC_ALL=C sort -u "$RESTORED_LIST" > /tmp/bp-restored.txt
        LC_ALL=C comm -23 /tmp/bp-pack.txt /tmp/bp-restored.txt > /tmp/bp-pack2.txt
        mv /tmp/bp-pack2.txt /tmp/bp-pack.txt
    fi
    echo "packing $(wc -l < /tmp/bp-pack.txt) entries"
    tar -C "$B" --no-recursion -I 'zstd -T0 -3' -cf "$out" -T /tmp/bp-pack.txt
    ls -l "$out"
}

# Unpack another group's output into the build directory and mark its stamps as old.
unpack() {
    local tarball=$1
    mkdir -p "$B"
    tar -C "$B" -I zstd -xf "$tarball"
    tar -I zstd -tf "$tarball" | sed 's|/$||' >> "$RESTORED_LIST"
    tar -I zstd -tf "$tarball" | grep -E '^\.[^/]+$' | sed "s|^|$B/|" >> "$OLD_LIST"
}

case $cmd in
    keys) keys ;;
    make) cmake_ "$@" ;;
    pack) pack "$@" ;;
    unpack) unpack "$@" ;;
    *) echo "unknown command $cmd" >&2; exit 1 ;;
esac
