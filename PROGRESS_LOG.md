# DroidDeck-Proton progress log

Newest first. Device = AYANEO Pocket FIT-class Android handheld running DroidDeck (glibc Arch ARM rootfs + Valve's Steam client).

## 2026-10-15

### Org build + source mirror
- **11-9.1 released** on The412Banner/DroidDeck-Proton (Latest, 2026-10-14) from the staged run 38617926549 artifacts; installed on the device, 11-7.5/11-7.6 removed.
- **Org repo** Droid-Deck/DroidDeck-Proton: main and ge-master brought level with this repo (the org-only README commit `1fbcff87` had the same tree as `0a50d239`). GE's `release.yml` disabled there too.
- **x.org outage:** org run 38706856896 failed in `misc`: `wget` of `xrandr-1.5.4.tar.xz` from www.x.org timed out (xorg.freedesktop.org down). Nothing wrong with the build itself.
- **Fix: source mirror.** The files the build fetches from outside GitHub (xrandr from x.org, wine-gecko from dl.winehq.org) are now hosted as assets of the org prerelease `build-sources`. `banner-proton/mirrored-sources.txt` lists them with sha256; a new `_group.yml` step puts verified copies in `contrib/` before make, so Makefile.in's wget rules are skipped. A missing or mismatched file falls back to the original URL. xrandr 1.5.4 checked against the sha512 published by Arch and Fedora.
- `_group.yml` is part of every group's cache key, so the next build rebuilds all groups once (ccache stays warm).

## 2026-10-14

### 11-9.1: rebased on GE-Proton11-9 (artifacts only, no release)
- **Base:** `ge-master` fast-forwarded `8d7a8cd2` → GE-Proton11-9 `01bfbf67` and merged into main. GE-Proton11-9 pins the same Valve Wine (`981e2f0b`), DXVK, vkd3d-proton, vkd3d, FEX (`FEX-2610`), lsteamclient, wineopenxr and protonfixes as `8d7a8cd2`: the component updates GE lists for 11-8 were already in our build. The real change is GE's patch set.
- **Wine:** new branch `banner-proton/11.9` (`e72ecf5d`), tags `bp-11.9-tier1..7`:
  - Tier 2: GE-Proton11-9's wine section run unmodified on Valve `981e2f0b`, no failed patches, one commit per section.
  - Tier 2.1 (`em-fixups/0067`) is now part of tier 2: the same patch file, applied by GE's em-fixups loop. No `tier2.1` tag on 11.9.
  - Tiers 3–7 cherry-picked from `banner-proton/11.7` with no conflicts; each tier's change is line-for-line the same as on 11.7.
  - The wineserver protocol is unchanged (new tier 4 `b1b17f2e` has the same headers as 11.7's).
  - The whole branch differs from `banner-proton/11.7` only in the 22 files GE changed.
- **Checked:** CachyOS has no release newer than `cachyos-11.0-20261005-slr`, so tier 3 stays at 17 commits. FEX stays at `14c92681` (the `FEX-2610` tag, GE's pin). DXVK stays at `2c94c5f2`; GE's two new DXVK patches apply to it with offsets only.
- **11-7.6** (FEX version name, no `xalia.pdb`) was never released. Its fixes carry over into 11-9.1.
- **Pins:** GE-Proton11-9 `01bfbf67b35418fdd705f2be09e0bfb43eece24b`. Valve Wine bleeding-edge `981e2f0b9007` (unchanged). FEX `FEX-2610-0-g14c9268`. DXVK `2c94c5f2` (v3.1.1-76, one past GE's `71ec7b5b`). vkd3d-proton `22307558` and vkd3d `fed0c341` (GE's pins, unchanged).
- **Per tier:**

  | Tier | Status |
  |---|---|
  | 1 | Same commit as 11.7 |
  | 2 | Fresh GE-Proton11-9 run, 0 failed patches. The `Verify wine tier 2` workflow reproduced it exactly (run 38617913701). |
  | 2.1 | Dropped: already upstream. GE's `em-fixups/0067` is the identical file, applied inside tier 2, and all 11 of its added lines are present. |
  | 3 | 18 commits (group start + 17 CachyOS), applied clean |
  | 4 | 11 commits, applied clean |
  | 5 | esync, applied clean |
  | 6 | 2 commits, applied clean |
  | 7 | 1 commit, applied clean |

  Every tier from 3 to 7 is line-for-line the same change as on 11.7. Nothing needed adjusting.
- **Wine branch:** proton-wine `banner-proton/11.9` tip `e72ecf5d`, tags `bp-11.9-tier1..7`.
- **Build:** run 38617926549 on `ff0f9052`, green in 28m41s with publish=false (no release, no tag). The wine group took 7 min with a warm ccache.
- **Verify:** all markers present (SSBS, VMEM, SFN, esync/fsync/ntsync, tier 6 and 7 traces). ntdll exports 291 = 291 and the protocol is unchanged. No `.dbg`/`.pdb` files are left in mono or Xalia.
- **Binaries:** `ntdll.so` is byte-identical to 11-7.5 (`844bed4e`).
- **Compared with 11-7.5:** 9673 vs 9674 entries; the one missing is `xalia.pdb`. Sizes differ only in `mountmgr.so`, `winewayland.so`, `winex11.so`, DXVK `d3d11`/`d3d9`/`dxgi` and `proton`.
- **Artifact:** `DroidDeck-Proton-11-9.1-aarch64`: tar.gz 625,414,776 B (artifact zip 625,415,309 B). GE-Proton11-9-aarch64.tar.gz is 647,938,895 B.
- **Status:** CI-green only. Not staged to the device yet (the user will download it later) and not device-proven.
- **CI note:** pushing `ge-master` started GE's own `release.yml` (failed with no jobs, no release). That workflow is now disabled in this repo's Actions settings.

## 2026-10-11

### In DroidDeck: third Proton source (DroidDeck #588, merged `78fcb60`)
- **Install from the app:** DroidDeck-Proton is listed in Setup › Proton versions and the Components Proton list, next to GE and CachyOS, with update checks for all three.
- **Device-proven:** Get → download → sha512 check → install of 11-7.5 in under a minute; it shows as "DroidDeck-Proton 11-7.5 (Compatible)"; DOOMBLADE ran on it with esync and FEX unixlibs.
- **Signed DroidDeck main APK** staged as `DroidDeck-main-78fcb60f.apk`.

### Found during testing
- **FEX has no version name** in our builds (DroidDeck shows "FEX (build without a version name)"; GE shows `FEX-2609-41-g82510eb`). Likely the FEX submodule is checked out without tags. Fix in the next build.
- **Tier 6 SD-card fix in use:** Half-Life 2 from the SD library loaded every DLL from the noexec card. Its slow launch (6–9 min to the menu) is Android FUSE + PRoot file lookups, and GE-Proton11-7 is just as slow, so the layer is not the cause.

### 11-7.5: only release, Latest
- **Release:** `DroidDeck-Proton-11-7.5` (main `0d09ab73`, wine `banner-proton/11.7` @ `847635ca`, run 38160269780) promoted from prerelease to full release and Latest. Notes rewritten in the short layout.
- **Cleanup:** releases and tags 11-7.3 and 11-7.4 deleted; 11-7.5 is the only release.
- **Tier 7** (`bp-11.7-tier7`): winedmo's DirectShow transform follows the downstream allocator's row order, so amstream FMVs are no longer upside down.
- **Device-proven:** Toy Story 2's intro FMVs (Activision logo, opening cutscenes) play upright at 30 fps.
- **Device state:** only `DroidDeck-Proton 11-7.5` is installed in `compatibilitytools.d`, next to GE-Proton11-7 and proton-cachyos 11.0-20261005. Toy Story 2 and DOOMBLADE need re-pointing to 11-7.5.

### 11-7.4
- **GE:** GE master bumped to `8d7a8cd2`:
  - Guild Wars Reforged wine-wayland alt+tab fix, added as tier-2 follow-up `bp-11.7-tier2.1` (`30839253`)
  - FNA fix for Meridian: New World (Wine-Mono)
  - protonfixes Project Torque fix
- **DXVK:** master `2c94c5f2` (v3.1.1-76), one commit past GE's pin.
- **Size:** Wine-Mono `.dbg`/`.pdb` files removed (40.5 MB unpacked); tarball 640.1 → 625.7 MB.
- **igdext:** the `igdext64.dll` copy error is fixed. There is no aarch64 igdext build, so `find_igdext_dll()` falls back to the x86_64 one. CI test: `banner-proton/test-igdext.py`.
- **Build:** run 38158179659, 28 min.

### 11-7.3: renamed to DroidDeck-Proton, tier 6
- **Rename:** repo renamed `The412Banner/Banner-Proton` → `The412Banner/DroidDeck-Proton`. Tool folder `DroidDeck-Proton <ver>` (DroidDeck shows it as "DroidDeck-Proton <ver> (Compatible)"), internal name `DroidDeck-Proton-<ver>`, asset `DroidDeck-Proton-<ver>-aarch64.tar.gz`, tag `DroidDeck-Proton-<ver>`. CI fails if "Banner-Proton" appears in assets, folder, version, vdf files or FFmpeg.
- **Tier 6** (`bp-11.7-tier6`), Arihany's fixes:
  - noexec/force_anon in `virtual.c` (games on an SD card start)
  - shlfileop drive-root copy fix
  - Source and binary guards in CI.
- **Device-proven:** DOOMBLADE boots on 11-7.3 with esync and FEX unixlibs. The SD-card fix is not device-tested yet.

### 11-7.2: esync built in
- **Tier 5** (`bp-11.7-tier5`): DroidDeck's `droiddeck-esync` patch (valve-11 series, by maxjivi05) built into Wine. DroidDeck detects "has esync built in" and needs no separate pack.
- **Version file:** written as `<ts> <name>`. 11-7.1's bare timestamp crashed protonfixes on launch.
- **Device-proven:** DOOMBLADE logs `droiddeck-esync: up and running`, never falls back to fsync, holds 91 eventfds, and shows 453 FEXMem regions (the FEX unixlib is in use).

### CI restructure (parallel groups)
- **Layout:** groups graphics / media / misc / fex run in parallel → wine → assemble → verify → release. Each group has its own ccache and a content-keyed output cache. Restored stamps are passed with `make -o`, so cached parts are never rebuilt.
- **Timings:** 79 min single-job before → 57 min cold → 25 min with only the compiler cache warm → **7–9 min fully cached**. Caches use about 2.3 GB of the 10 GB limit.
- **Rule:** all work and builds happen on `main` only, because Actions caches are branch-scoped.

## 2026-10-10 / 11: first build (Banner-Proton 11-7.1)
- **Base:** GE-Proton master after 11-7 + Valve bleeding-edge Wine `981e2f0b` (tiers 1–2).
- **Tier 3:** 17 CachyOS game fixes.
- **Tier 4:** our Bannerlator fixes (WINE_FORCE_SSBS, WINEVMEMMAXSIZE, RtlIsEcCode, sharedgpures.sys, gdiplus, xinput, rsaenh, MAX_FONT_HANDLES, dai_xinput).
- **Size:** debug stripping (`-ggdb` dropped + `strip-dist.py`); tarball 640 MB vs GE's 646 MB.

## Open items
- **SD-card fix (tier 6):** device test owed. Run a game from DroidDeck's SD-card "Second library" with `WINEDEBUG=+virtual` and look for `force_anon: reading` and no "noexec filesystem?".
- **Parked:**
  - `.tar.xz` packing (about 640 → 370 MB download)
  - CachyOS extras: low-latency DXVK/VKD3D, DXVK-Sarek with Armada's probe tweak, small script options; GStreamer only if needed
  - Feature ideas: ARM game-fix DB, FEX profiles, pre-installed runtimes, Adreno defaults
- **Tracking:** CI should follow new GE releases and rebase tiers 2.1–7 on each one.
