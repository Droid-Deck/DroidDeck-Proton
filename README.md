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
script, unchanged) with Wine built in six tiers. Each tier is a tag on the Wine branch, so any one of
them can be bisected or turned off on its own.

| Tier | Contents | Tag |
|---|---|---|
| 1 | Valve Proton Wine, `bleeding-edge` | `bp-11.11-tier1` |
| 2 | Everything GE-Proton11-11 applies to Wine, plus two GE fixes from after 11-11 | `bp-11.11-tier2` |
| 3 | CachyOS game fixes GE doesn't already carry | `bp-11.11-tier3` |
| 4 | Our portable fixes from the Bannerlator layers | `bp-11.11-tier4` |
| 5 | DroidDeck esync, built in | `bp-11.11-tier5` |
| 6 | SD card fixes (games on `noexec` storage, drive-root copies) | `bp-11.11-tier6` |

Up to 11-10.1 there was a tier 7 (DirectShow FMVs upside down). GE-Proton11-11 carries the same fix
(`ge-video-rework/0096`), so it is part of tier 2 now.

Wine source: [`The412Banner/proton-wine`](https://github.com/The412Banner/proton-wine), branch
`banner-proton/11.11` (the `wine` submodule). Versions and pins: `banner-proton/VERSION` and `banner-proton/PINS`.

_Formerly Banner-Proton; releases up to 11-7.2 used the old name._

<details>
<summary><b>Pins (11-11.1)</b></summary>

| Component | Commit |
|---|---|
| GE-Proton (`proton-ge-custom` tag `GE-Proton11-11`) | `c0c2ee35e6d4d3bff4d39c6246ac46636434feb8` |
| DXVK (same as GE: v3.1.1-134) | `2cb40186c43d617b5bd349a3756721aa4bd24b6d` |
| Valve Wine `bleeding-edge` (same as GE, 2026-10-16) | `c53678ab22a85f0fad3588dd34f0452a463bd015` |
| FEX (same as GE: `FEX-2610-30`) | `741e146fdf5a89517e1a67e3c899907cfba6131a` |
| CachyOS Wine `cachyos_11.0_20261014/main` (release `cachyos-11.0-20261015-slr`) | `cd14106e4fc0f96006005b07985e49cc1517e9c0` |
| DroidDeck-Proton Wine `banner-proton/11.11` | `219dddec24cbf30aca79f7189073a127134a4fec` |

vkd3d-proton, vkd3d, d7vk, dxvk-nvapi, dxvk-igdext, lsteamclient, wineopenxr and protonfixes are
GE-Proton11-11's pins. DXVK, Valve Wine and FEX did not change from 11-10.1.

</details>

<details>
<summary><b>Tier 2 – GE-Proton</b></summary>

All of GE-Proton's Wine patching at `GE-Proton11-11` (`c0c2ee35`) plus two later GE fixes (below), applied by GE's own `protonprep`
Wine section on tier 1, one commit per section: configure revert, EM-11 wine-wayland + wineopenxr + EM fixups,
wine-staging (with GE's exclusions and rebased sets), game patches, hotfixes, pending upstream patches
and GE's custom patches (FSR, Reflex, OptiScaler, video rework, DS5 haptics, Bluetooth LE, …). Everything
applied cleanly. The `Verify wine tier 2` workflow re-runs GE's section on tier 1 and checks the result
matches tier 2 plus its follow-ups.

New in GE-Proton11-11 (hotfix): games no longer freeze when a video is skipped while MPEG-1 audio plays
(GE #865), MPEG-1 video through AMStream no longer upside down (GE #863), no heap corruption from
scaled video frames (GE #864, aderumier), vkd3d-proton no longer trips Easy Anti-Cheat in Star Citizen
and Hunt: Showdown (GE #858), Star Citizen AMD AGS override removed, protonfixes update (Star Citizen
.NET 4.8, mod loaders, Windows version re-applied after winetricks).

Taken from GE's master after 11-11 (cherry-picked with `-x` into this repo's `protonprep`):
- ntdll: take the in-flight alert when a `RtlWaitOnAddress()` wait times out (Space Marine 2 crash after
  long play; from proton-je, Jason Eggleston) – GE `98efe1cd`
- winewayland: advertise the OpenVR/OpenXR Vulkan device pseudo-extensions like winex11 (VR games on
  Wine's Wayland driver) – GE `e15b1e15`, GE #852
- lsteamclient: keep the automatic PlayStation (Sony) Steam Input fallback when Steam Input is off for
  the game but on globally – GE `bbef7006` (lsteamclient patch 0017, applied at build time)

Earlier, in GE-Proton11-10: Valve Wine bleeding-edge 2026-10-16 (upstream syscall emulation for EAC/EOS
launchers, x86_64 only), ACE anti-cheat driver fixes (ntoskrnl, lsass SamSs stub; Arknights: Endfield),
Star Citizen's bundled AMD AGS, faster shared SRW lock releases, llvm-libc fixes, the PlayStation
controller XInput fallback no longer rescanning HID devices on every poll, Bluetooth DS4/DualSense
rumble through the fallback, KWin per-monitor HDR state and owned-popup destruction fixes
(`em-fixups/0071`, `0072`), MonoGame song replay fix (`ge-video-rework/0093`, `0094`).

GE's non-Wine changes arrive through the `ge-master` merge: DXVK v3.1.1-134, D7VK rebased on it,
vkd3d-proton synchronization fix, FEX-2610-30, and the `proton` script's controller defaults.

</details>

<details>
<summary><b>Tier 3 – CachyOS</b></summary>

Cherry-picked (`-x`) from CachyOS Wine (the first 18 carried from 11-10.1 and still in CachyOS
`cd14106e`, release `cachyos-11.0-20261015-slr`):

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

**Not picked:** anything GE or Valve Wine already carries (CachyOS 20261014's crypt32 certificate-chain
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
(maxjivi05), applied unchanged. Adds eventfd/shared-memory sync to wineserver and ntdll (Elizabeth
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
- **CI guards** – Wine protocol and ntdll exports unchanged; tier 6 fixes and the winedmo row order fix present in source and
  binaries (trace strings); no leftover "Banner-Proton" names.

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
Arihany and GameNative (SD card fixes) · FEX-Emu, DXVK, vkd3d-proton, dxvk-nvapi, d7vk and every
patch author named in the commit history.

## License

Proton and its components keep their own licenses: see [LICENSE](LICENSE), [LICENSE.proton](LICENSE.proton)
and `dist.LICENSE` in the tarball. Wine is LGPL-2.1-or-later. DroidDeck-Proton's own scripts and patches
follow the licenses of the files they change.
