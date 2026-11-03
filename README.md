# DroidDeck-Proton

A GE-Proton based Proton build for **ARM64 (aarch64) Linux**, made for
[DroidDeck](https://github.com/Droid-Deck/DroidDeck): Valve's Steam client in an Arch Linux ARM rootfs,
running Windows games through ARM64 Proton with FEX.

> [!Important]
> DroidDeck-Proton is an unofficial build. It is **not** GE-Proton, Proton-CachyOS or Valve's Proton and is
> not affiliated with GloriousEggroll, CachyOS or Valve. Please report problems here, not to those projects.

## Install

1. Download `DroidDeck-Proton-<version>-aarch64.tar.gz` from [Releases](../../releases).
2. Extract it into Steam's `compatibilitytools.d` folder.
3. Restart Steam and pick **DroidDeck-Proton &lt;version&gt;** as the game's compatibility tool.

## What's inside

DroidDeck-Proton is GE-Proton (DXVK, vkd3d-proton, FEX, protonfixes, media stack and the `proton`
script, unchanged) with Wine built in seven tiers. Each tier is a tag on the Wine branch, so any one of
them can be bisected or turned off on its own.

| Tier | Contents | Tag |
|---|---|---|
| 1 | Valve Proton Wine, `bleeding-edge` | `bp-11.12-tier1` |
| 2 | Everything GE-Proton11-12 applies to Wine | `bp-11.12-tier2` |
| 3 | CachyOS game fixes GE doesn't already carry | `bp-11.12-tier3` |
| 4 | Our portable fixes from the Bannerlator layers | `bp-11.12-tier4` |
| 5 | DroidDeck esync, built in | `bp-11.12-tier5` |
| 6 | SD card fixes (games on `noexec` storage, drive-root copies) | `bp-11.12-tier6` |
| 7 | .NET mod loaders on ARM64 (upstream Wine fix, since 11-11.2) | `bp-11.12-tier7` |

Up to 11-10.1 tier 7 was the DirectShow FMV row order fix. GE-Proton11-11 carries the same fix
(`ge-video-rework/0096`), so it is part of tier 2 now, and tier 7 is a new fix since 11-11.2.

Wine source: [`The412Banner/proton-wine`](https://github.com/The412Banner/proton-wine), branch
`banner-proton/11.12` (the `wine` submodule). Versions and pins: `banner-proton/VERSION` and `banner-proton/PINS`.

_Formerly Banner-Proton; releases up to 11-7.2 used the old name._

<details>
<summary><b>Pins (GE-Proton11-12 base)</b></summary>

| Component | Commit |
|---|---|
| GE-Proton (`proton-ge-custom` tag `GE-Proton11-12`) | `f85547f0ea51ac356ab42b4de57b927b0044cc85` |
| DXVK (same as GE: v3.1.1-174) | `f863776806824486d709fee16ea619c03e22def4` |
| Valve Wine `bleeding-edge` (same as GE, 2026-10-31 + later commits) | `fda79a585939fb7512dc220a11249f9ffe825fcf` |
| FEX (same as GE: `FEX-2610-116`, plus `patches/fex`) | `02e24ca5c01ed0c864466ed573db347336f70170` |
| CachyOS Wine `cachyos_11.0_20261014/main` (release `cachyos-11.0-20261015-slr`) | `cd14106e4fc0f96006005b07985e49cc1517e9c0` |
| CachyOS Wine `cachyos_11.0_20261014/dev` (unreleased; two HID commits in tier 3) | `c3808057d6` |
| DroidDeck-Proton Wine `banner-proton/11.12` (+ the winex11 offscreen-check cache) | `303894db765bad9936de9a532cb833dada939d58` |

vkd3d-proton (v3.1), vkd3d, d7vk, dxvk-nvapi (v0.9.3), dxvk-igdext, lsteamclient, wineopenxr and protonfixes are
GE-Proton11-12's pins.

The move to GE-Proton11-12 carries every fix of 11-11.11 below: tiers 3–7 and the offscreen-check cache are
cherry-picked onto `banner-proton/11.12` unchanged except the esync tier (ported, see tier 5), and the deferred
Wine and FEX patches apply at build time as before. The 32-bit lost wake fix (11-11.5) is rebased onto GE's newer
stale-alert fix. The three GE master fixes 11-11.1 took early are GE's own now.

History on GE-Proton11-11: 11-11.2 is 11-11.1 plus
tier 7. 11-11.3 is 11-11.2 plus the WoW ARM64EC game patch. 11-11.4 is 11-11.3 plus Android shared-storage file ownership.
11-11.5 is 11-11.4 plus the 32-bit lost wake fix (Battle.net freezes). 11-11.6 is 11-11.5 plus the winex11
offscreen-check cache for DroidDeck's Performance mode: off unless `WINE_OFFSCREEN_CHECK_MS` is set (DroidDeck sets
100 only with Performance mode on), so the present path does not ask wineserver for the window's relatives twice a frame.
11-11.7 is 11-11.6 plus Wine's own DLLs no longer reported read-only (MapleStory copies ws2_32.dll and crashed).
11-11.8 is 11-11.7 plus Android's shared storage treated as case-insensitive, so creating files in a large folder there
no longer lists the whole folder each time (Battle.net installs into a Games folder slowed to about 100 KB/s).
11-11.9 is 11-11.8 plus Dmage22's FEX-D2 fixes for Blizzard's protected loaders in the bundled FEX (`patches/fex`,
applied on top of the FEX pin at every build). StarCraft Remastered's 32-bit client no longer faults in `ClientSdk.dll`
when it starts.
11-11.10 is 11-11.9 plus a ws2_32 game patch for DiRT 3 and DiRT Showdown: with their motion telemetry on, a `sendto()`
on the socket they closed at the end of a race (or when leaving Joyride) reports 0 bytes sent instead of failing with
error 10038, which stopped the game.
11-11.11 is 11-11.10 plus 32-bit executables loaded at their preferred base again. Only 64-bit `.exe` files are
relocated to the top of the address space now, so older 32-bit games and their loaders find themselves at the address
they were built for, as on Valve's Proton. A loader that starts a 32-bit game suspended can read and patch it at
0x400000 again.

</details>

<details>
<summary><b>Tier 2 – GE-Proton</b></summary>

All of GE-Proton's Wine patching at `GE-Proton11-12` (`f85547f0`), applied by GE's own `protonprep`
Wine section on tier 1, one commit per section: configure revert, EM-11 wine-wayland + wineopenxr + EM fixups,
wine-staging (with GE's exclusions and rebased sets), game patches, hotfixes, pending upstream patches
and GE's custom patches (FSR, Reflex, OptiScaler, video rework, DS5 haptics, Bluetooth LE, …). Everything
applied cleanly. The `Verify wine tier 2` workflow re-runs GE's section on tier 1 and checks the result
matches tier 2 plus its follow-ups.

New in GE-Proton11-12:
- Valve Wine bleeding-edge 2026-10-31 and later: XInput rescans controllers only when a device could have
  changed (replaces the Far Cry 4 and Witcher 3 hacks), thread pool worker timeout 60 s, Voice Capture DSP
  (`mfwmaaec`) audio capture, HID input reports cut to their declared length
- controllers: DualSense haptics and adaptive triggers together over USB in Final Fantasy VII Rebirth and the
  Horizon games (GE #860), Armored Core VI through the Steam Input fallback, `PROTON_STEAM_INPUT_XBOX_PROMPTS`
  (GE #841), Where Winds Meet touchpad (GE #829)
- windowing: Hyprland fullscreen regression (GE #871), Fcitx5 IME freeze on Wine-Wayland (GE #798), a present/focus
  deadlock (GE #908), animated cursors (GE #919), X11 pointer-grab hang (GE #920, Syrupdesu), Cinnamon title bars
  (GE #767), DayZ device creation on Wayland with an OpenXR runtime installed (GE #852)
- video: MSFS 2024 intro speed (GE #389), AAC intros stopping (GE #882), The Godfather FMV flicker (GE #909, AITUS95),
  arcade and Konami movie fixes (aderumier), khdays-port cutscene deadlock (GE #899), VRChat RTSP streams (l12436)
- ntsync: a mutex a process closed while one of its threads still waited on it is abandoned when that thread dies
  (Jason Eggleston, WineHQ 60524)
- the three GE master fixes 11-11.1 took early are part of it: the Space Marine 2 stale-alert fix (now with its
  test, GE `960acd0a`), winewayland OpenVR/OpenXR device extensions (GE #852), lsteamclient's Sony fallback

Earlier, in GE-Proton11-11 (hotfix): games no longer freeze when a video is skipped while MPEG-1 audio plays
(GE #865), MPEG-1 video through AMStream no longer upside down (GE #863), no heap corruption from
scaled video frames (GE #864, aderumier), vkd3d-proton no longer trips Easy Anti-Cheat in Star Citizen
and Hunt: Showdown (GE #858), Star Citizen AMD AGS override removed, protonfixes update (Star Citizen
.NET 4.8, mod loaders, Windows version re-applied after winetricks).

Earlier, in GE-Proton11-10: Valve Wine bleeding-edge 2026-10-16 (upstream syscall emulation for EAC/EOS
launchers, x86_64 only), ACE anti-cheat driver fixes (ntoskrnl, lsass SamSs stub; Arknights: Endfield),
Star Citizen's bundled AMD AGS, faster shared SRW lock releases, llvm-libc fixes, the PlayStation
controller XInput fallback no longer rescanning HID devices on every poll, Bluetooth DS4/DualSense
rumble through the fallback, KWin per-monitor HDR state and owned-popup destruction fixes
(`em-fixups/0071`, `0072`), MonoGame song replay fix (`ge-video-rework/0093`, `0094`).

GE's non-Wine changes arrive through the merge of `GE-Proton11-12`: DXVK v3.1.1-174 (command submission
throttling and memory eviction rework, present timing fixes), the D7VK DirectDraw/D3D7 rework, VKD3D-Proton 3.1,
DXVK-NVAPI 0.9.3, FEX-2610-116, and the `proton` script's controller defaults.

</details>

<details>
<summary><b>Tier 3 – CachyOS</b></summary>

Cherry-picked (`-x`) from CachyOS Wine, all still in CachyOS `cd14106e` (release `cachyos-11.0-20261015-slr`),
carried unchanged from 11-11.11, plus two from CachyOS's unreleased `cachyos_11.0_20261014/dev` (`c3808057d6`):

- ntdll: `WINE_DISABLE_SFN` option (Yakuza 5 cutscenes) – Pedro Nishiyama
- win32u: opaque webviews for Wuthering Waves – NelloKudo
- pdh: no access violation in PdhCloseQuery on a bad handle; powrprof: stub PowerReadACValueIndex – Ziia Shi
- ntdll: SystemPowerInformation semi-stub, RtlAreLongPathsEnabled – Etaash Mathamsetty
- mountmgr.sys: StorageDeviceTrimProperty stub – Jactry Zeng
- d3d8: valid box in vertex/index buffer Lock – Stefan Dösinger
- ddraw: enumerate the ramp device; pass the active device to material_activate – Elizabeth Figura, Rémi Bernon
- wined3d: pixel-format fixes – Elizabeth Figura, Zhiyi Zhang, Patrick Zacharias
- xaudio2_7: Darksiders Warmastered crash workaround – NelloKudo
- mfplat: R8_UINT in MFCreateDXGISurfaceBuffer – Nikolay Sivov
- setupapi: initialize the Service value size when checking for winehid devices – M0n7y5 (new in 20261014)
- crypt32: keep the order of authenticated attributes when verifying signatures, with tests (WineHQ MR
  11824: FL Studio, Genshin Impact / Zenless Zone Zero CN editions) – Michael Nelson (new in 20261015)
- winebus.sys: an error for IOCTL_HID_GET_STRING when a device has no serial number; hidclass.sys: multi-TLC
  child devices named after the FDO instance id, not the serial number – Ivo Ivanov (from the dev branch, new in 11-12)

**Not picked:** the dev branch's setupapi "fail `SetupDiGetDeviceInterfaceAlias` instead of aborting" (GE carries the
same author's full implementation, `proton-ds5-haptic/0102`, Fabian Wosar); its winepipewire/mmdevapi hotplug and USB
instance-id series and coreaudio (CachyOS's audio stack); anything GE or Valve Wine already carries (CachyOS 20261014's crypt32 certificate-chain
and schannel fixes, the ACE anti-cheat fixes); win32u "don't decorate maximized windows" (same line as GE's
frameless-window change), and CachyOS 20261015's revert of it; CachyOS 20261015's winewayland owned-popup
reparenting (written against CachyOS's wine-wayland, conflicts with GE's EM-11 tree); x86_64-only code (EAC/EOS syscall
forwarding); changes that conflict with GE's winedmo video rework; branding/policy defaults (fsync on,
Windows 11, version string, font smoothing); larger features left for later (winepipewire, futex
tuning, FSR4/MLFG, kernel-object series, LTO/clang).

</details>

<details>
<summary><b>Tier 4 – Our fixes (Bannerlator layer v14)</b></summary>

- `WINE_FORCE_SSBS` switch on top of Wine MR 12262 (`=0` restores the old behaviour)
- `WINEVMEMMAXSIZE` (MB): cap a single NtAllocateVirtualMemory (inert when unset)
- ntdll: bounds-check `RtlIsEcCode` (Denuvo unwinding loop, Need for Speed Heat)
- mf/topology_loader: restore the upstream type when optional insertion fails – NelloKudo
- sharedgpures.sys: earlier shared-resource protocol (D3D9→D3D11 video on DXVK < 3.0)
- rsaenh: hold the public key during CPVerifySignature
- gdiplus: clamp degenerate spans instead of asserting (EA app installer)
- xinput: survive a transient WAIT_FAILED in the update thread
- win32u: MAX_FONT_HANDLES 5000 → 32768
- GE game fix `dai_xinput` (Dragon Age: Inquisition controller, SteamGameId 1222690 only)

**Not carried:** winegstreamer and media fixes that GE's winedmo rework replaces or already covers,
fixes Valve Wine already has, and everything Android/bionic-specific.

</details>

<details>
<summary><b>Tier 5 – DroidDeck esync</b></summary>

`droiddeck-esync/patches/valve-11/0001-droiddeck-esync.patch` from
[Droid-Deck/DroidDeck-Components](https://github.com/Droid-Deck/DroidDeck-Components) `780ab619de`
(maxjivi05). On `banner-proton/11.12` it is ported to GE-Proton11-12's in-process mutex change (Jason Eggleston,
GE `6161ec53`): the client cache entry keeps both GE's serial and esync's shared-memory index, and the server destroys
an esync object before GE's ntsync orphan check. Adds eventfd/shared-memory sync to wineserver and ntdll (Elizabeth
Figura's esync design), so no separate esync pack is needed. Sync order stays ntsync → fsync → esync
(`WINEESYNC`) → server; the log says `droiddeck-esync: up and running.` when esync is used. No wineserver
request or ntdll.so export changes (CI checks both).

</details>

<details>
<summary><b>Tier 6 – SD card fixes (Arihany)</b></summary>

From our Wine 11 port (`proton-wine` `proton_11.0`, `497c384f`), offsets only:

- **ntdll – PE images in anonymous memory** (`virtual.c`; originally GameNative's). Private image
  mappings are read into anonymous memory instead of `mmap`ed, so games on a `noexec` mount (an Android
  SD card) start instead of failing with "noexec filesystem?".
- **shell32 – drive-root copies** (`shlfileop.c`). A bare root like `D:\` keeps its backslash, so
  `SHFileOperation` copies between drive roots no longer crash.

Not taken: the `LC_ALL=C.UTF-8` default (bionic-only; DroidDeck uses glibc).

</details>

<details>
<summary><b>Game patch – WoW Forever ARM64EC</b></summary>

Deferred build-time patch for **`WowB-ARM64.exe`** (ARM64EC) on aarch64 — not committed in the `wine` submodule:

[`patches/game-patches/wow-forever-arm64ec-ntdll.patch`](patches/game-patches/wow-forever-arm64ec-ntdll.patch)

Applied after **`banner-proton/prep.sh`** by **`banner-proton/apply-deferred-game-patches.sh`**
([`.github/workflows/_group.yml`](.github/workflows/_group.yml)). Omitted from **`patches/protonprep-valve-staging.sh`**
until the same change is tagged on **`The412Banner/proton-wine`**.

| Area | What it fixes |
|---|---|
| `signal_arm64.c` | Zero `CONTEXT` before `save_context` (stale debug regs → intermittent **Game Initialization Failed: I**) |
| `asm.h` | TEB → KSDT syscall stubs; ARM64EC fallback to `__wine_syscall_dispatcher` when TEB slots are empty |
| `syscall.c` / `thread.c` | Publish dispatcher in KSDT; `ntdll_arm64ec_sync_syscall_dispatch()` on EC thread start / after `ChpeV2` |
| `env.c` | NLS section map fallback when section maps fail |
| `virtual.c` | Map-time init of `__wine_syscall_dispatcher` for manually mapped ntdll SEC_IMAGE views |

</details>

<details>
<summary><b>Game patch – DiRT 3 / DiRT Showdown telemetry (error 10038)</b></summary>

Deferred build-time patch, applied by **`banner-proton/apply-deferred-game-patches.sh`** like the WoW one:

[`patches/game-patches/dirt-telemetry-sendto-closed-socket.patch`](patches/game-patches/dirt-telemetry-sendto-closed-socket.patch)

DiRT 3 (`dirt3_game.exe`) and DiRT Showdown (`showdown.exe`, `showdown_avx.exe`) keep sending motion telemetry on the
UDP socket they closed at the end of a race and when leaving Joyride. `sendto()` fails with `WSAENOTSOCK` and the game
stops with *"sendto failed with error 10038"*; Windows does the same. For these three executables only, `sendto()` in
`dlls/ws2_32/socket.c` reports 0 bytes sent for that failure (the executable name is checked once per process). Every
other game and every other `sendto()` result are unchanged. Same behaviour as
[DiRTTelemetryErrorFix](https://github.com/RoccoC/DiRTTelemetryErrorFix) by RoccoC, based on Carsten Gottschling's fix.

</details>

<details>
<summary><b>Tier 7 – .NET mod loaders on ARM64</b></summary>

Upstream Wine `c5a96a0b6c` (Brendan Shanks, CodeWeavers; in Wine 11.4), cherry-picked by maxjivi05
(proton-wine PR #1):

- **kernelbase – `GetNativeSystemInfo()` in x64 processes** (`memory.c`). An x64 process under ARM64EC
  now gets `PROCESSOR_ARCHITECTURE_AMD64`, as on Windows, instead of ARM64. .NET 6 reported ARM64 from
  it, so MonoMod (Harmony, SMAPI, MelonLoader 0.7.x) wrote an ARM64 jump into x64 CoreCLR code and the
  runtime died with `c000001d` (FEX-Emu/FEX#6014, Droid-Deck/DroidDeck#611). Diagnosis by utkarshdalal
  (GameNative/proton-wine#94), report by whatsupbros.

</details>

<details>
<summary><b>Building</b></summary>

Builds run on GitHub Actions (`ubuntu-24.04-arm`, Valve's `steamrt4` arm64 Proton SDK), like GE's
aarch64 builds.

- **`Build DroidDeck-Proton (aarch64)`** – GE's `configure.sh --target-arch=arm64`, split into parallel
  groups (graphics, FEX, misc, media → Wine, then assemble). Output is stripped (Wine-Mono debug files
  removed) and packed as `DroidDeck-Proton-<version>-aarch64.tar.gz` + `.sha512sum` in GE's layout.
  Inputs: **publish** (release from main), **prerelease** (not marked latest), **compare_with** (diff
  against an earlier release).
- **Caches** – each group's output is keyed by its sources and skipped when cached; per-group ccache;
  SDK image cache.
- **CI guards** – Wine protocol and ntdll exports unchanged; tier 6 and 7 fixes and the winedmo row order fix present in source and
  binaries (trace strings); WoW Forever deferred patch markers after `apply-deferred-game-patches.sh`; no leftover "Banner-Proton" names.

Local builds: follow [docs/README.GE-Proton.md](docs/README.GE-Proton.md), using `banner-proton/prep.sh`
instead of `patches/protonprep-valve-staging.sh` and
`../configure.sh --target-arch=arm64 --build-name=DroidDeck-Proton-<version> --display-name="DroidDeck-Proton <version>"`.

</details>

## Credits

[Valve](https://github.com/ValveSoftware/Proton) (Proton, Wine, Steam Linux Runtime) ·
[GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom) and GE-Proton contributors ·
[Wine](https://gitlab.winehq.org/wine/wine) and [wine-staging](https://gitlab.winehq.org/wine/wine-staging) developers ·
[CachyOS](https://github.com/CachyOS/proton-cachyos) · NelloKudo · Etaash Mathamsetty ·
Elizabeth Figura (esync, fsync, ntsync) · maxjivi05 / DroidDeck (droiddeck-esync) ·
Arihany and GameNative (SD card fixes) · Brendan Shanks, utkarshdalal, whatsupbros
(.NET fix) · arusiasotto (WoW ARM64EC fix) · Dmage22 ([FEX-D2](https://github.com/Dmage22/FEX-D2), Blizzard loader fixes) · oldschoola
([linux_maplestory](https://github.com/oldschoola/linux_maplestory), MapleStory research) · FEX-Emu, DXVK, vkd3d-proton, dxvk-nvapi, d7vk and every
patch author named in the commit history.

## License

Proton and its components keep their own licenses: see [LICENSE](LICENSE), [LICENSE.proton](LICENSE.proton)
and `dist.LICENSE` in the tarball. Wine is LGPL-2.1-or-later. DroidDeck-Proton's own scripts and patches
follow the licenses of the files they change.
