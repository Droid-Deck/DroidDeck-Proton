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
| 1 | Valve Proton Wine, `bleeding-edge` | `bp-11.7-tier1` |
| 2 | Everything GE-Proton applies to Wine (+ later GE follow-ups) | `bp-11.7-tier2`, `bp-11.7-tier2.1` |
| 3 | CachyOS game fixes GE doesn't already carry | `bp-11.7-tier3` |
| 4 | Our portable fixes from the Bannerlator layers | `bp-11.7-tier4` |
| 5 | DroidDeck esync, built in | `bp-11.7-tier5` |
| 6 | SD card fixes (games on `noexec` storage, drive-root copies) | `bp-11.7-tier6` |
| 7 | Media fixes (DirectShow FMVs no longer upside down) | `bp-11.7-tier7` |

Wine source: [`The412Banner/proton-wine`](https://github.com/The412Banner/proton-wine), branch
`banner-proton/11.7` (the `wine` submodule). Versions and pins: `banner-proton/VERSION` and `banner-proton/PINS`.

_Formerly Banner-Proton; releases up to 11-7.2 used the old name._

<details>
<summary><b>Pins (11-7.5)</b></summary>

| Component | Commit |
|---|---|
| GE-Proton (`proton-ge-custom` master, past GE-Proton11-7) | `8d7a8cd2966e2f3e409f9b0551ec90def7cd2b87` |
| DXVK (`doitsujin/dxvk` master, one past GE's pin) | `2c94c5f25cf75c313ef2a55b2e0c9276d67c28d6` |
| Valve Wine `bleeding-edge` (same as GE) | `981e2f0b9007fd70a6e0ed6119cb18f4164e26f9` |
| CachyOS Wine `cachyos_11.0_20261001/main` | `2ce6b44caa66a56ec99c7826ae564c088abc1b9f` |
| DroidDeck-Proton Wine `banner-proton/11.7` | `847635ca0ec7871fa9a3df80283c20dcdc09d572` |

</details>

<details>
<summary><b>Tier 2 – GE-Proton</b></summary>

All of GE-Proton's Wine patching at `proton-ge-custom` `49c50f4b`, applied by GE's own `protonprep`
Wine section, one commit per section: configure revert, EM-11 wine-wayland + wineopenxr + EM fixups,
wine-staging (with GE's exclusions and rebased sets), game patches, hotfixes, pending upstream patches
and GE's custom patches (FSR, Reflex, OptiScaler, video rework, DS5 haptics, Bluetooth LE, …). Everything
applied cleanly. The `Verify wine tier 2` workflow re-runs GE's section on tier 1 and checks the result
matches tier 2 plus its follow-ups.

**Follow-ups** (committed on top; tier tags are never rewritten):

- `bp-11.7-tier2.1` (GE `8d7a8cd2`): `em-fixups/0067` winewayland keeps renderer subsurfaces when
  minimized (Guild Wars Reforged alt+tab).

GE's non-Wine changes arrive through the `ge-master` merge: the Wine-Mono FNA stencil fix (Meridian:
New World) and the protonfixes bump (Project Torque).

</details>

<details>
<summary><b>Tier 3 – CachyOS</b></summary>

Cherry-picked (`-x`) from CachyOS Wine `2ce6b44c`:

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

**Not picked:** anything GE or Valve Wine already carries; x86_64-only code (EAC/EOS syscall
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
<summary><b>Tier 7 – Media fixes</b></summary>

- **winedmo – DirectShow transforms follow the allocator's row order** (`quartz_transform.c`).
  amstream's DirectDraw stream connects with bottom-up RGB but hands out top-down surfaces, signalled by
  a negative `biHeight` on each sample. GE's winedmo transform ignored that, so MPEG-1 FMVs played
  through amstream (e.g. Toy Story 2) were upside down. It now follows the sample's row order; allocators
  that report no type are unaffected. (GE fixed the same issue for qasf only.)

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
- **CI guards** – Wine protocol and ntdll exports unchanged; tier 6 and 7 fixes present in source and
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
