# DroidDeck-Proton progress log

Newest first. Device = AYANEO Pocket FIT-class Android handheld running DroidDeck (glibc Arch ARM rootfs + Valve's Steam client).

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
- **Next build:** fetch FEX tags so FEX reports its version; strip `files/share/xalia/xalia.pdb` (1.4 MB).
- **Parked:**
  - `.tar.xz` packing (about 640 → 370 MB download)
  - CachyOS extras: low-latency DXVK/VKD3D, DXVK-Sarek with Armada's probe tweak, small script options; GStreamer only if needed
  - Feature ideas: ARM game-fix DB, FEX profiles, pre-installed runtimes, Adreno defaults
- **Tracking:** CI should follow new GE releases and rebase tiers 2.1–7 on each one.
