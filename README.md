# Banner-Proton

Banner-Proton is a GE-Proton based Proton build for **ARM64 (aarch64) Linux**. It is made for
[DroidDeck](https://github.com/The412Banner), which runs Valve's Steam client in an Arch Linux ARM
rootfs and runs Windows games through ARM64 Proton with FEX. It installs like any other Proton tool:
extract the release tarball into `compatibilitytools.d` and pick **Banner-Proton &lt;version&gt;** in Steam.

> [!Important]
> Banner-Proton is an unofficial build. It is **not** GE-Proton, Proton-CachyOS or Valve's Proton, and
> it is not affiliated with GloriousEggroll, CachyOS or Valve. Please do not report Banner-Proton
> problems to those projects; open an issue here instead.

Status: **prerelease / proof of concept.** Builds come from GitHub Actions; device testing is still to come.

## How it is put together

Banner-Proton is a fork of [proton-ge-custom](https://github.com/GloriousEggroll/proton-ge-custom)
(its history is kept on the `ge-master` branch). Wine is built in four tiers, and every tier is a
tag on the wine branch so it can be bisected or turned off on its own:

| Tier | What | Where | Tag |
|---|---|---|---|
| 1 | Valve Proton wine, `bleeding-edge` (the base Proton Experimental's bleeding-edge builds use) | `ValveSoftware/wine` | `bp-11.7-tier1` |
| 2 | Everything GE-Proton applies to wine (wine-staging, EM-11 wine-wayland, game fixes, hotfixes, video rework, FSR, Reflex, OptiScaler, DS5, Bluetooth LE ...) | GE's own `protonprep` wine section, run unmodified | `bp-11.7-tier2` |
| 3 | CachyOS game fixes that GE does not already carry | `CachyOS/wine-cachyos` | `bp-11.7-tier3` |
| 4 | Our portable Wine fixes from the Bannerlator layers | `The412Banner/proton-wine` `proton_11.7.1-GE` | `bp-11.7-tier4` |

The wine source is [`The412Banner/proton-wine`](https://github.com/The412Banner/proton-wine) branch
`banner-proton/11.7`; this repository's `wine` submodule points at it. Everything outside wine
(DXVK, vkd3d-proton, dxvk-nvapi, d7vk, FEX, protonfixes, lsteamclient, the `proton` script, fonts,
media stack ...) is GE-Proton's, prepared by GE's own `patches/protonprep-valve-staging.sh`
(`banner-proton/prep.sh` runs it without its wine section, because tier 2 already contains it).
The `Verify wine tier 2` workflow re-runs GE's wine section on tier 1 and checks the result is
exactly tier 2.

### Pins (version 11-7.1)

| | Commit |
|---|---|
| GE-Proton (`proton-ge-custom` master, includes everything in GE-Proton11-7 and the work after it) | `49c50f4b2546b06cea3493803f18a13bb2a2f0c8` |
| Valve wine `bleeding-edge` (same commit GE master pins) | `981e2f0b9007fd70a6e0ed6119cb18f4164e26f9` |
| CachyOS wine, `cachyos_11.0_20261001/main` (wine of proton-cachyos `cachyos-11.0-20261005-slr`) | `2ce6b44caa66a56ec99c7826ae564c088abc1b9f` |
| Banner-Proton wine, `banner-proton/11.7` | `709d1c14a84338514032e2053bcad02cec91c9ee` |

The machine-readable list is `banner-proton/PINS`; the version is `banner-proton/VERSION`.

## Patch list

### Tier 2: GE-Proton

All of GE-Proton's wine patching at `proton-ge-custom` `49c50f4b`, applied by GE's script section by
section (one commit per section): the configure revert, EM-11 wine-wayland + wineopenxr + wineland child
rendering + EM fixups, wine-staging (`patchinstall.py --all` with GE's exclusions plus GE's rebased
staging sets), GE game patches, hotfixes and backports, pending upstream patches, and GE's custom patches
(FSR fullscreen hack, NVIDIA Reflex, OptiScaler, GE video rework, proton-ds5-haptic, Bluetooth LE, ...).
Every patch applied cleanly; nothing was skipped. See GE's script for the full list and its credits.

### Tier 3: CachyOS

Cherry-picked (with `-x`) from CachyOS wine `2ce6b44c`, in this order:

- HACK: ntdll: Add `WINE_DISABLE_SFN` option, fixes Yakuza 5 cutscenes (Pedro Nishiyama)
- HACK: win32u: Force opaque webviews for Wuthering Waves (NelloKudo)
- pdh: Avoid access violation in PdhCloseQuery on bad handle (Ziia Shi)
- powrprof: Stub PowerReadACValueIndex (Ziia Shi)
- ntdll: Add SystemPowerInformation semi-stub (Etaash Mathamsetty)
- ntdll: Implement RtlAreLongPathsEnabled (Etaash Mathamsetty)
- include: Update STORAGE_BUS_TYPE in ntddstor.h; mountmgr.sys: Stub StorageDeviceTrimProperty query (Jactry Zeng)
- d3d8: Build a valid box in vertex/index buffer Lock (Stefan Dösinger, 2 patches)
- ddraw: Enumerate the ramp device (Elizabeth Figura); ddraw: Pass the active device to material_activate (Rémi Bernon)
- wined3d: Remove the "iPixelFormat" field (Elizabeth Figura); Reset internal_format_set when using the backup DC (Zhiyi Zhang); Access the right pixel format in swapchain_gl_present() (Patrick Zacharias, applied by hand at the moved call site)
- HACK: xaudio2_7: Workaround a crash in Darksiders: Warmastered Edition (NelloKudo; rebased onto GE's DS5 audio tracing, NULL buffer kept valid)
- mfplat: Handle R8_UINT format in MFCreateDXGISurfaceBuffer() (Nikolay Sivov; library part only)

Already in GE-Proton or Valve wine in some form, so not picked again: the EM wine-wayland, ntoskrnl,
amdxc/atiadlxx/atidxx and winebus/Steam Input work (Etaash Mathamsetty), the GE-origin hacks CachyOS
carries (FSR, Reflex, OptiScaler, host block, PSO2, Vanguard, Guilty Gear, Assetto Corsa, RRF flags,
winealsa channels), AF_UNIX sockets, icuuc/icuin, keyboard layouts, NCryptDecrypt, OLE clipboard,
the Monster Hunter Wilds audio set, the RDR2/WRC9/Diabotical wine.inf entries, NelloKudo's
mfsrcsnk/mfreadwrite/WMA/winedmo/evr media fixes, NtUserEnableMouseInPointer, RegCreateKeyTransacted,
ControlServiceEx, IsNativeVhdBoot, top-down reservation, drive_c case folding.

Deliberately left out:

- Not applicable to an aarch64 build: EAC/EOS syscall forwarding (x86_64 `signal_x86_64.c` only).
- Conflict with GE's own design: the winegstreamer force/orientation switches, media-converter
  reverts, raw parser and WM reader stream patches (GE's video rework replaced that code with winedmo).
- Policy/branding, not game fixes: fsync on by default, Windows 11 by default, "(CachyOS)" version
  string, font smoothing defaults, dotfiles shown.
- Features rather than game fixes, left for later: the winepipewire.drv audio driver and system-thread
  mmdevapi rework (M0n7y5, Alexandre Julliard), futex queue tuning (Marc-Aurel Zent), epoll_wait
  resolution, AMD FSR4/MLFG (amdxc), d2d1/windowscodecs/dnsapi upstream backports, the ntoskrnl/wdfldr
  kernel-object series, LTO/clang build changes.

### Tier 4: ours (from `proton_11.7.1-GE`, Bannerlator layer v14)

- `WINE_FORCE_SSBS`: Valve wine already contains Wine MR 12262 (keep the host SSBS bit, ignore reserved
  CPSR bits); we add only the switch. `WINE_FORCE_SSBS=0` gives the pre-MR behaviour back.
- `WINEVMEMMAXSIZE` (MB): cap a single NtAllocateVirtualMemory size (inert when unset).
- ntdll: bounds-check `RtlIsEcCode` (nested access-violation loop unwinding Denuvo frames, Need for Speed Heat).
- mf/topology_loader: restore the upstream media type when optional insertion fails (NelloKudo).
- sharedgpures.sys: the earlier shared-resource protocol on D3DKMT sharing (D3D9 to D3D11 video on DXVK before 3.0).
- rsaenh: hold the public key for the duration of CPVerifySignature.
- gdiplus: clamp degenerate spans instead of asserting (EA app installer).
- xinput: survive a transient WAIT_FAILED in the update thread.
- win32u: MAX_FONT_HANDLES 5000 to 32768.
- GE game fix `dai_xinput` (Dragon Age: Inquisition controller, Cameron Moore; SteamGameId 1222690 only).

Not carried, with the reason:

- NelloKudo's winegstreamer WMA decoder, output-PTS and media-source retry fixes, and our two
  winegstreamer duration fixes: GE's video rework removes those winegstreamer files; GE ships its own
  winedmo WMA decoder and timing.
- mfsrcsnk SetCurrentPosition seek, mfreadwrite ANY_STREAM / audio alignment / native compressed
  formats / async SAMPLE_READY timestamp, and the winedmo extension-less URL fix: GE's reworked
  mfsrcsnk, mfreadwrite and winedmo already do the same thing.
- "keep winegstreamer the default byte-stream handler, winedmo opt-in": GE's design is winedmo-only.
- winedmo big-endian PCM rewrite: it only replaced a filter that did not compile against Termux's
  FFmpeg 8; GE's pinned FFmpeg builds the original.
- The media-converter environment gates: GE removed them on purpose.
- rsaenh HMAC inner-hash crash: Valve wine already fixes it.
- Everything Android specific (bionic patches, sysvshm, shm_utils, 16 KB alignment), lsteamclient
  server browser, userspace ntsync, DirectAudio, winewayland touch/HDR and the XP theme.

## Building

All builds run on GitHub Actions, on native ARM64 runners (`ubuntu-24.04-arm`) inside Valve's
`steamrt4` arm64 Proton SDK image, like GE's aarch64 builds:

- `Build Banner-Proton (aarch64)` (`.github/workflows/build-aarch64.yml`): GE's `configure.sh
  --target-arch=arm64` and `make dist`, split into up to four chained stages that hand the build tree
  to each other when one runner's time runs out. Then everything is stripped
  (`strip --strip-unneeded` for ELF, `llvm-strip --strip-unneeded` for PE, no debug files) and packed as
  `Banner-Proton-<version>-aarch64.tar.gz` plus `.sha512sum`, with the same layout as GE's tarball
  (`toolmanifest.vdf`, `compatibilitytool.vdf`, `proton`, `files/`). With "publish" it becomes a prerelease.
- Caches: ccache for the native and the llvm-mingw cross compilers, the SDK image, and prebuilt
  DXVK/vkd3d-proton/d7vk/dxvk-nvapi, FEX, FFmpeg and the speech libraries, keyed by their commits.

Local builds follow GE's instructions in [docs/README.GE-Proton.md](docs/README.GE-Proton.md), with
`banner-proton/prep.sh` instead of `patches/protonprep-valve-staging.sh` and
`../configure.sh --target-arch=arm64 --build-name=Banner-Proton-<version>-aarch64 --display-name="Banner-Proton <version>"`.

## Credits

- [Valve](https://github.com/ValveSoftware/Proton) for Proton and its wine, and the Steam Linux Runtime SDK.
- [GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom) and the GE-Proton contributors for GE-Proton and its patch set.
- The [Wine](https://gitlab.winehq.org/wine/wine) and [wine-staging](https://gitlab.winehq.org/wine/wine-staging) developers.
- [CachyOS](https://github.com/CachyOS/proton-cachyos) for proton-cachyos and wine-cachyos.
- NelloKudo (Nello De Gregoris) for the media and game fixes, Etaash Mathamsetty for the EM work,
  and every patch author named above and in the commit history.
- FEX-Emu, DXVK, vkd3d-proton, dxvk-nvapi, d7vk and the other projects bundled by GE-Proton.

## License

Proton and its components are distributed under their own licenses; see [LICENSE](LICENSE),
[LICENSE.proton](LICENSE.proton) and `dist.LICENSE` (shipped in the tarball). Wine is LGPL-2.1-or-later.
Banner-Proton's own scripts and patches use the same licenses as the files they change.
