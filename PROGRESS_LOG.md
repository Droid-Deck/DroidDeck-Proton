# DroidDeck-Proton progress log

Newest first. Device = AYANEO Pocket FIT-class Android handheld running DroidDeck (glibc Arch ARM rootfs + Valve's Steam client).

## 2026-11-03

### 11-12 rebase: GE-Proton11-12, Valve fda79a58, two CachyOS dev commits, PR #9 (rebase/11-12, CI pending, NOT device-tested)
- **Why:** user asked to move to GE-Proton11-12 (released 2026-11-03) and add what GE and CachyOS have that we lack, without losing any of our fixes. User's choices: take the CachyOS dev picks, include K11MCH1's PR #9, work on a new branch off main.
- **Branch:** `rebase/11-12` off main `e0de7fb0` (11-11.11). `ef7f0313` merges GE-Proton11-12 `f85547f0`: protonprep and the Space Marine 2 patch become GE's (the three GE master commits 11-11.1 took early are in 11-12), README stays ours, `proton` and `Makefile.in` merge cleanly. `ge-master` on the org is not moved yet (still `c0c2ee35`).
- **Wine:** `banner-proton/11.12` `303894db` on The412Banner/proton-wine, tags `bp-11.12-tier1..7`; `banner-proton/11.11` untouched.
  - Tier 1: Valve bleeding-edge `fda79a58` (GE's pin, +21 commits on `c53678ab`).
  - Tier 2: GE-Proton11-12's wine section run unmodified, one commit per section, 0 failed patches.
  - Tier 3: the 20 CachyOS commits of 11.11 unchanged + winebus.sys `b3795230` and hidclass.sys `447acb9a` from the unreleased `cachyos_11.0_20261014/dev`. setupapi `598410aa` not taken: GE has Fabian Wosar's full `SetupDiGetDeviceInterfaceAlias` (`proton-ds5-haptic/0102`) and the stub fix conflicts with it.
  - Tiers 4, 6, 7 and the offscreen-check cache: `git range-diff` against 11.11 says identical.
  - Tier 5 (droiddeck-esync) conflicted with GE's `server-keep-in-process-mutex-closed-while-in-use` (Jason Eggleston, GE `6161ec53`, adds keep/release_kept_inproc_sync requests and an ntsync orphan-mutex list). Ported by keeping both (serial + shm_idx in the cache entry; release closes the fd if any, frees the esync index, then releases a kept object; `esync_destroy()` before GE's ntsync orphan check). `gcc -fsyntax-only` of the server and ntdll unix files clean. The Components esync pack for GE-Proton11-12 fails the same way (Components run 41613296661); not touched here.
  - Protocol: no change after tier 4, so `WINE_PROTOCOL_BASE` = tier 4 `a7caaeb2`; `tools/make_requests` gives the committed headers.
- **Deferred patches:** `ntdll-i386-recover-lost-wake-on-address` (Max, 11-11.5) hunk 3 failed on GE's newer stale-alert fix (`960acd0a`); rebased: the i386 build takes that alert with the same 100 ms bounded wait inside GE's `!queued && STATUS_TIMEOUT` check and reports the wake. clang i686/aarch64-windows syntax check clean. All seven apply in order on `303894db`.
- **FEX:** GE's pin moves to `02e24ca5` (FEX-2610-116). 0001-0012 apply (two with offsets); PR #9 (K11MCH1) merged as `028c2a8c`: 0013 applies after them, rpmalloc 0001 applies on the unchanged rpmalloc pin `ed227446`.
- **Commits:** `ef7f0313` merge, `0e86e5c0` wine/PINS/README/i386 patch, `028c2a8c` PR #9. VERSION stays 11-11.11 (bump at the release cut).
- **CI run 1** (headSha `1520c23a`): Verify wine tier 2 41667549700 **green** (a fresh GE-Proton11-12 run on tier 1 reproduces `bp-11.12-tier2` exactly). Build 41667555200 **failed** in all four groups at "Prepare sources": GE's own `patches/protonfixes/0003` (Kingdoms of Amalur) is already in the protonfixes pin GE bumped to (`28a02c25`), `patch` skips the files and exits 1, and prep.sh treats that as fatal (GE's CI ignores it). The "Wine protocol unchanged" job (protocol + tier 6/7 + deferred patch source markers) passed.
- **Fix:** prep.sh skips a patch that reverses cleanly ("already in the tree, skipped") and still fails on anything else. Checked locally on protonfixes `28a02c25` and the rest of the prep section.
- **CI run 2** 41669299861 (headSha `7c3a3659`, still named 11-11.11): prep passed; FEX (with PR #9) and media groups green, the rest still building when the user chose the name.
- **User decision (2026-11-03):** "make it 11-12.1 and rebuild": VERSION 11-12.1 now, so the test build sits next to 11-11.11 in Steam (instead of keeping 11-11.11 until the release cut). Run 3 is queued behind run 2 (same concurrency group) and reuses its group caches (VERSION is not in the cache keys).
- **Components:** the GE-Proton11-12 esync pack (same port, series `ge-11`, branch `fix/esync-ge-11-12` `cf6e67ce`) built in Components run 41671479709: control reproduces GE's ntdll.so and wineserver, smoke test passed (esstress: stock 1 failure, pack 0); Test run 41671485778 green. Not published (branch).
- **CI run 2** finished green (all groups, assemble, Verify tarball): every marker present (esync "up and running", tier 4/6 strings, winedmo rows, FEX-2610-116-g02e24ca with patches/fex, igdext). Against 11-11.11: 9677 → 9690 entries; only in old: protonfixes `2479810.py` (protonfixes removed its Gray Zone Warfare EAC fix, #664); only in new: `mfwmaaec.dll` (Valve), 32-bit `wineopenxr` (GE), new protonfixes gamefixes (292030, 1041720, Ultima Online).
- **CI run 3** 41675222109 (headSha `058df6ba`, 11-12.1): green; every group restored from run 2's caches, assemble and Verify tarball green. Artifact `DroidDeck-Proton-11-12.1-aarch64` 626,402,267 B (zip).
- **Install (user's go: "hand install the layer for testing"):** new folder `compatibilitytools.d/DroidDeck-Proton 11-12.1` next to the 11-11.11 test build (nothing overwritten); staged in `/sdcard/Download/DroidDeck-Proton/` with sha512 checked on host and device; owner and SELinux labels as the existing tool. DroidDeck adds its wrapper at the next session start. Undo: delete that one folder.
- **INSTALLED 2026-11-03 ~17:20 UTC (not game-tested yet):** staged `/sdcard/Download/DroidDeck-Proton/DroidDeck-Proton-11-12.1-058df6ba-aarch64.tar.gz` (+ .sha512sum), sha512 `5cecabac…` matches the artifact on host and device. Extracted as `compatibilitytools.d/DroidDeck-Proton 11-12.1`: 9690 entries (= tarball), all owned by 10195, all labelled `app_data_file:s0:c195,c256,c512,c768`, ntdll.so `7bbbc054…` and wineserver `d464caaa…` equal the tarball's, version `1793724530 DroidDeck-Proton-11-12.1`. The 11-11.11 test build and the 11-11.11 release (in `compatibilitytools.d-backup`) are untouched. DroidDeck was running; the new tool shows after the next Steam session start. The esync port runs only with the esync sync choice (fsync is the default).
- **Device test 1 (user, 2026-11-03 17:17 UTC): DiRT Showdown** (added game 2660302055, SD card), session `files/logs/2026-11-03-03-steam`, game debug logs on (`+seh,+unwind,+loaddll`).
  - Ran on `1793724530 DroidDeck-Proton-11-12.1` (droiddeck-esync launches.log); wineserver `droiddeck-esync: up and running.` (the ported tier 5). Prefix upgraded from GE-Proton11-11 to "11.0-100" (GE's new prefix version naming).
  - In game ~33 s (focus 17:17:40 to 17:18:13), then the user closed the session ("the app asked for a clean exit"; Proton's KeyboardInterrupt traceback is that shutdown). No crash: Android crash buffer has only an xsud entry from 16:40 UTC (before the test, root helper), no tombstones, app.log clean, DXVK log 0 errors (Turnip), no ws2_32 10038.
  - **Found:** the game's "DirectInput EnumDevices" thread (01c0:02f8) faults 2 s after it starts: `wow64win.dll+0x1eba0` writes at 0x0e090000, the top of that thread's 32-bit stack (esp 0x0e08fe94), then ~1,600 access violations at address 0 and 255 in `wow64.dll+0x1cc88`, until EXCEPTION_STACK_OVERFLOW in 32-bit ntdll (+0x3df51). The thread dies; the game keeps running. The 3 "nested exception on signal stack" lines are winedevice.exe at shutdown (also in the 11-11.6 log of 10-26).
  - User: the controller worked in DiRT Showdown on 11-12.1, so the game found it despite that thread dying.
  - Not known yet whether this is new in 11-12.1: the only older Showdown log (10-26, 11-11.6, benchmark mode) has no stack overflow, but a benchmark may not enumerate input the same way. Next: the same launch on 11-11.11 with the same debug logs, compare thread "DirectInput EnumDevices".
- **Next (user, 2026-11-03):** DOOM (2016) on 11-12.1 (64-bit, ARM64EC + FEX with PR #9), its usual settings with only the Proton switched.
- **Resume:** pick `DroidDeck-Proton 11-12.1` per game in Steam and run the test list; check logcat for FATAL and the game's log for `droiddeck-esync: up and running` (esync choice).
- **Device test plan (user's yes before install):** DiRT 3 or Showdown (telemetry), Battle.net (rebased 32-bit wake fix), a game from the SD card, NINJA GAIDEN (FMV), DOOM (2016), one controller game; logcat FATAL check; esync in the session log.
- **Resume:** branch and wine tags are pushed; next is the CI run, then the device test.

## 2026-10-25

### 11-11.6: winex11 offscreen-check cache for DroidDeck's Performance mode (main, Latest, device-tested)
- **Why:** DroidDeck's close-the-gap work (DroidDeck PR #1563, Performance mode, merged 10-25). Each present made `client_surface_update_offscreen()` call `needs_offscreen_rendering()` twice, and each call asks wineserver for the window's relatives; at high frame rates the game spent much of `vkQueuePresentKHR` waiting on wineserver.
- **Fix:** proton-wine `ff9db6f6` + `bab12909`: the check is reused for `WINE_OFFSCREEN_CHECK_MS` milliseconds; unset or 0 keeps the per-call check. DroidDeck sets 100 with Performance mode on and 0 otherwise; older app versions never set it.
- **Wine:** `banner-proton/11.11` fast-forwarded `40653419` → `bab12909` (backup `refs/backup/20261025/banner-proton-11.11-before-offscreen-cache`).
- **Repo:** VERSION 11-11.6, wine submodule → `bab12909`, README pins/notes. Built first on The412Banner/DroidDeck-Proton `release/11-11.6` (run 40231819046, not published), then the org branch (run 40236905066, compare with 11-11.5: only `winex11.so` changed size, +80 B; ntdll exports unchanged, 291).
- **Device test (AYANEO Pocket FIT, hand-installed `DroidDeck-Proton 11-11.6`, DroidDeck Preview with Performance mode, 11-11.5 and 11-11.6 alternated, cooled):** D3D11 2725/2630 → 3495/3313 fps (+27 %), D3D9 2451/2089 → 3209/3237 (+42 %); Performance mode off D3D11 ~1083 (unchanged); DiRT Showdown 93.0 vs 89.7 (one run each, normal spread, GPU-bound); no FATAL. Session log `droiddeck-esync: DroidDeck-Proton 11-11.6` confirmed the build in use.
- **Release:** user's go → org `main` fast-forwarded `0b077896` → `89226ed6` (backup `refs/backup/20261025/main-before-11-11.6`), build run 40238848757 green → `DroidDeck-Proton-11-11.6` is Latest, tag → `89226ed6`, 3 assets. Release notes in the 11-11.2 style; 11-11.3, 11-11.4 and 11-11.5 notes rewritten the same way (PRs #3, #4, #5).

## 2026-10-24

### 11-11.2: tier 7, .NET mod loaders on ARM64 (main, CI-green prerelease, NOT device-tested)
- **Why:** Discord #bug-reports thread 1559868756098940978 (whatsupbros): Drova + MelonLoader 0.6.6/0.7.3 dies with .NET `c000001d` on 11-7.5 and the 10-23 preview; FEX-Emu/FEX#6014, Droid-Deck/DroidDeck#611 (SMAPI). Cause found by utkarshdalal (GameNative/proton-wine#94, merged 10-22): `GetNativeSystemInfo()` returns ARM64 in an x64 ARM64EC process, .NET 6 reports Arm64, MonoMod writes an ARM64 jump over x64 CoreCLR code.
- **Fix:** upstream Wine `c5a96a0b6c` (Brendan Shanks; in Wine 11.4), proton-wine PR #1 by maxjivi05 (change lines identical to upstream, checked). User's go to merge and build 11-11.2.
- **Wine:** `banner-proton/11.11` fast-forwarded `219dddec` → `40653419` (PR #1 now merged), tag `bp-11.11-tier7` (annotated; tiers 1–6 are lightweight). Backup `refs/backup/20261024/banner-proton-11.11-before-native-sysinfo` on proton-wine.
- **Repo:** VERSION 11-11.2, PINS tier tags 1..7, wine submodule → `40653419`, CI source marker for the tier 7 hunk in `dlls/kernelbase/memory.c`, README tiers/pins/credits.
- **PR author's proof (not ours):** REDMAGIC tablet, 11-11.1 with only `kernelbase.dll` swapped: `GetNativeSystemInfo` 12 → 9 (AMD64), back to 12 with the shipped DLL.
- **CI:** `Verify wine tier 2` run 40120875090 green. Build run 40120885224 on `5aaa70dd` green (fex/media/graphics/misc/wine2/wine3 skipped = cached/normal); new source check finds the tier 7 hunk in `dlls/kernelbase/memory.c`; tarball markers all ok, FEX `FEX-2610-30-g741e146`, ntdll exports 291 = 291. Compared with 11-11.1: 9677 = 9677 entries, no size changes, 2383 files differ only in content (sampled diffs are the 6-byte PE header/timestamp kind; `kernelbase.dll` for aarch64/i386/x86_64 among them), 2 ICU DLLs mode 0644 → 0444.
- **Release:** prerelease `DroidDeck-Proton-11-11.2` (tag → `5aaa70dd`), 3 assets, tarball 625,550,481 B.
- **Install path for users:** DroidDeck's in-app installer (`ProtonExtras.kt`) only reads `Droid-Deck/DroidDeck-Proton` and skips prereleases, so testers can't get this build from the app; an org release would be offered to everyone.
- **Staged for the device test:** tarball in `/sdcard/Download/DroidDeck-Proton/`, sha512 `8cc370a5…376b` matches on host and device. Test program `/sdcard/Download/sysinfo-probe/sysinfo-probe.exe` (x64, prints `GetNativeSystemInfo` / `GetSystemInfo` / `IsWow64Process2` and writes `sysinfo-probe.txt`): expected 12 (ARM64) on 11-11.1, 9 (AMD64) on 11-11.2.
- **Installed on the device** by hand as `compatibilitytools.d/DroidDeck-Proton 11-11.2` (user's go: probe + one regression game, no .NET game): 9677 entries, all owned by the app (uid 10195), SELinux labels the same as 11-11.1 (toybox `chcon --reference` did nothing, labels set explicitly), `ntdll.so`/`wineserver`/`shell32.dll` sha256 match build-info.
- **Device test, probe (2026-10-24, same non-Steam shortcut and prefix):** 11-11.1 → `GetNativeSystemInfo` 12 (ARM64), NOT FIXED; 11-11.2 → 9 (AMD64), FIXED. `GetSystemInfo` 9 and `IsWow64Process2` 0x0/0xaa64 on both. Session log confirms protonfixes ran on `DroidDeck-Proton-11-11.1` then `DroidDeck-Proton-11-11.2`. No crashes in logcat, no new tombstones. No .NET/MelonLoader game tested (user's choice).
- **Device test, regression:** DiRT Showdown on 11-11.2 starts (process chain through `DroidDeck-Proton 11-11.2/droiddeck-proton-wrap`, its `ntdll.so` loaded, splash/loading screen at ~200 fps, ~1.07 GB RSS); no crashes in logcat, no new tombstones. Only the loading screen was captured.
- **Org:** user's go (2026-10-24) to release 11-11.2 on Droid-Deck/DroidDeck-Proton as Latest. Org `main` fast-forwarded to this repo (only PROGRESS_LOG differs from the tested `5aaa70dd`), `ge-master` already level (`c0c2ee35`); backup `refs/backup/20261024/main-before-11-11.2-org` on the org. Build with publish=true, prerelease=false, compare_with `DroidDeck-Proton-11-11.1`. Run ID and result below.
- **Org release:** org verify run 40128139906 and build run 40128144077 (on `79d4ffc4`) green → `DroidDeck-Proton-11-11.2` is Latest on the org, tag → `79d4ffc4`, 3 assets, tarball 625,534,036 B, build-info wine `40653419` with tiers 1–7. Compared with org 11-11.1: 9677 = 9677 entries, no size or mode changes, 2383 files with different content (kernelbase.dll for all three arches among them), ntdll exports 291 = 291. `ntdll.so` and `wineserver` identical to the personal build; `shell32.dll` differs (PE build timestamp, as with earlier personal/org pairs). Release notes in the 11-11.1 layout ("New in 11-11.2", 11-11.1 changes folded).
- **Discord:** reply posted in the #bug-reports .NET thread (BannerBot embed card, reply to whatsupbros), saying the org build was running and 11-11.2 would be in the app shortly.
- **Open:** personal 11-11.2 prerelease kept until the user says; MelonLoader game test by whatsupbros.
- **Earlier plan:** device test (a .NET 6 / MelonLoader 0.7.3 game + a regression game). Org only after device-proven and the user's go.

## 2026-10-23 (2)

### 11-11.1: GE-Proton11-11, CachyOS 20261015, three GE master fixes
- **Why:** user asked for upstream fixes after 11-10.1 went to the org. GE-Proton11-11 (hotfix: video deadlock/upside-down/heap fixes, vkd3d-proton EAC fix) and CachyOS 20261015 (crypt32 MR 11824). Valve Wine, DXVK, vkd3d-proton and FEX pins unchanged.
- **Base:** `ge-master` `8f204747` → GE-Proton11-11 `c0c2ee35`, merged into main (no conflicts). Backups `refs/backup/20261023/main-before-11-11.1` (`48bcff61`), `ge-master-before-11-11.1` (`8f204747`).
- **GE master picks** (user's choice, handheld-relevant): `98efe1cd` Space Marine 2 (ntdll `RtlWaitOnAddress`), `e15b1e15` winewayland OpenVR/OpenXR extensions (DroidDeck VR runs on X11 today, so this only matters with `PROTON_ENABLE_WAYLAND`; the conflict in protonprep was other GE patches' lines, only this patch's lines kept), `bbef7006` lsteamclient 0017 Sony fallback (applies without 0016 AC6, checked on a scratch copy). Not taken: the x86_64-only WoW64 exit fix (`signal_x86_64.c`), Hyprland, RuneScape/HDR, purple launcher, cmd choice, GNOME tray, Star Citizen DLSS.
- **Wine:** `banner-proton/11.11` `219dddec`, tags `bp-11.11-tier1..6`:
  - Tier 1: Valve `c53678ab` (same as 11.10).
  - Tier 2: this repo's protonprep wine section, unmodified, one commit per section (2-1..2-7 + drop configure), 0 failed patches. Diff to `bp-11.10-tier2`: ntdll/sync.c, winedmo (GE 0095–0097), winewayland vulkan.c, wine.inf (AGS revert) only.
  - Tier 3: 18 carried from 11.10 + CachyOS `45f4a562`/`393bdcf6` crypt32 (MR 11824). Left out: the win32u decoration revert (never carried) and winewayland popup reparenting `d9849606` (conflicts with GE's EM-11 window.c: no `window_rect` etc.).
  - Tiers 4–6 cherry-picked from 11.10, clean.
  - **Tier 7 dropped:** GE-Proton11-11's `ge-video-rework/0096` is the same winedmo row order fix (GE #863); cherry-pick conflicted in quartz_transform.c. CI source/binary markers switched to GE's version (`Switching output to %s rows.`).
- **Built / CI:** `Verify wine tier 2` run 39947730838 green (fresh GE run == tier 2). Build run 39947785994 on `0184fc1c` green (wine2/wine3 skipped as for 11-10.1); winedmo row order markers found in source and in the aarch64, i386 and x86_64 `winedmo.dll`. Published as prerelease `DroidDeck-Proton-11-11.1` (tag → `0184fc1c`), tarball 625,575,904 B, sha512 `e8c2bf24…34ad`.
- **Device:** installed by hand next to 11-10.1 as `compatibilitytools.d/DroidDeck-Proton 11-11.1`: sha512 checked on host and device, 9677/9677 entries, all owned by the app (uid 10195), SELinux labels the same as 11-10.1. DroidDeck's `steam-compatibility` adds the wrapper at the next session start. Not game-tested yet.
- **Org 11-10.1:** org run 39945045568 green; org release `DroidDeck-Proton-11-10.1` is Latest, tag → `48bcff61`, 3 assets, wine `7e20ceeb`. The personal 11-10.1 prerelease was deleted (user's go); its tag stays.
- **Device test (user, 2026-10-23):** DiRT Showdown runs; NINJA GAIDEN SIGMA runs with its FMV cutscenes upright at 60 fps (intro and subtitled cutscene). Both confirmed launched through `DroidDeck-Proton 11-11.1` (process list); no crashes in logcat, no new tombstones. Not tested: a PlayStation controller, Space Marine 2.
- **Org:** user's go to release 11-11.1 on Droid-Deck/DroidDeck-Proton as Latest. Org `main`/`ge-master` brought level with this repo (fast-forwards, backups `refs/backup/20261023/*-before-11-11.1-org` on the org), build with publish=true, prerelease=false, compare_with `DroidDeck-Proton-11-10.1`.
- **Org release:** org run 39955941334 green (verify run 39955909737 green) → `DroidDeck-Proton-11-11.1` is Latest on the org, tag → `56265e2e`, 3 assets, wine `219dddec`. Compared with the personal build the user tested: same 9677 files and sizes (only the random name of one cached `.msi` in the default prefix differs), `ntdll.so` and `wineserver` identical, `shell32.dll` differs in 4 bytes (PE build timestamp), as between the 11-10.1 personal and org builds.
- **Release notes:** org 11-10.1 and 11-11.1 bodies rewritten in the 11-9.1 layout (what's inside, new in this version with upstream issue/PR numbers, tested, credits, pins and hashes). The Sony fallback fix (lsteamclient 0017) is GloriousEggroll's, a follow-up to GE PR #807 (Nickdom1's Armored Core VI actions, not taken).

## 2026-10-23

### 11-10.1: device-proven, org brought level, org release
- **Device:** the user ran games on 11-10.1 on the Pocket FIT (installed 2026-10-21 by hand into `compatibilitytools.d/DroidDeck-Proton 11-10.1`). User's go to promote it.
- **Org repo** Droid-Deck/DroidDeck-Proton: `main` `bc343c25` → `7b9723af` and `ge-master` `01bfbf67` → `8f204747`, both fast-forwards (the org had no commits of its own). Backups `refs/backup/20261023/main-before-11-10.1` and `ge-master-before-11-10.1` on the org.
- **Org build:** dispatched with publish=true, prerelease=false (Latest, user's choice), compare_with `DroidDeck-Proton-11-9.1`. Run ID and result in the next entry.
- **Next:** check the org release (tag = built commit, 3 assets, sha512), then delete the superseded personal 11-10.1 prerelease only on the user's say.

## 2026-10-19

### 11-10.1: rebased on GE-Proton11-10 and CachyOS 20261014
- **Base:** `ge-master` fast-forwarded `01bfbf67` → GE-Proton11-10 `8f204747` and merged into main. DXVK now follows GE's pin `2cb40186` (v3.1.1-134, 58 commits past our old `2c94c5f2`). FEX `741e146f` (FEX-2610-30), D7VK and vkd3d-proton are GE's new pins.
- **Wine:** new branch `banner-proton/11.10` (`7e20ceeb`), tags `bp-11.10-tier1..7`:
  - Tier 1: Valve bleeding-edge `c53678ab` (2026-10-16), 22 commits past `981e2f0b`. CachyOS 20261014 is built on the same commit.
  - Tier 2: GE-Proton11-10's wine section run unmodified, one commit per section, 0 failed patches. The `Verify wine tier 2` workflow reproduced it exactly (run 39278598888).
  - Tier 3: the 17 CachyOS commits carried from 11.9 (all still in `cachyos-11.0-20261014-slr`, wine `6a7adb2a`) plus `setupapi: Initialize the Service value size when checking for winehid devices` (new). Left out: win32u "don't let the drivers decorate maximized windows" (same line as GE's frameless-window change); crypt32 CERT_CHAIN_ENGINE_CONFIG and schannel fixes (already in GE); ACE fixes (in GE-Proton11-10).
  - Tiers 4–7 cherry-picked from `banner-proton/11.9` with no conflicts; each tier is the same change as on 11.9. New tier 4 = `5130c288` (`WINE_PROTOCOL_BASE`); the protocol does not change in tiers 5–7.
  - Valve's new syscall emulation (Syscall User Dispatch) is x86_64-only code and is not built for aarch64.
- **Build:** run 39278603403 on branch `rebase/11-10` (`496a921f`), green in 61 min (DXVK/FEX/D7VK/vkd3d-proton rebuilt), publish=false.
- **Verify:** all markers present; ntdll exports 291 = 291; FEX `FEX-2610-30-g741e146`; igdext copy OK; no `.dbg`/`.pdb`.
- **Compared with 11-9.1:** 9675 vs 9673 entries, the two new ones are `lsass.exe` (GE's SamSs stub for ACE). Sizes differ in DXVK, D7VK, vkd3d-proton, xinput, ntoskrnl, winewayland, ntdll, wine.inf, the prefix registry and `proton`.
- **Artifact:** `DroidDeck-Proton-11-10.1-aarch64.tar.gz` 625,560,774 B.
- **Status:** CI-green; published as a prerelease for device testing. The org repo gets it after it is device-proven.

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
