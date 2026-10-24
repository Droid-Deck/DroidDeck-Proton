# Device testing (DroidDeck + ADB)

Host-side helpers for **Battle.net → WoW Classic Era** on DroidDeck with this Proton build
(`DroidDeck-Proton 11-11.1 ARM64EC WoW` on branch `wine-tier8-upstream` @ `faf0d50d`).

WoW-Mobile is deprecated for this work; keep scripts, captures, and notes here.

## Guest install (once)

Copy onto the DroidDeck Linux rootfs:

| File | Guest path |
|------|------------|
| `device/scripts/Launch-BattleNet.sh` | `/usr/local/bin/Launch-BattleNet.sh` |
| `device/scripts/wow-forever.env.example` | `/usr/local/etc/wow-forever.env` (edit `BNET_APPID`, `WOW_LOGDIR`) |

**Steam shortcut (4153382437):** compatibility tool = this Proton build; launch options:
`/usr/local/bin/Launch-BattleNet.sh %command%`

**Non-Steam card:** `droiddeck-proton-run --app 4153382437` (Bnet closes on Play by design).

## Capture from host

Requires USB debugging and a **running** DroidDeck session (`content://com.droiddeck.launcher.agent` `guest`).

```bash
export ADB_SERIAL=912601210098   # your device
./device/scripts/capture-tier8-steam-run.sh my-run-tag
```

Output: `device/captures/<tag>/` (gitignored except `RESULTS.md`). Guest staging:
`/root/Storage/DroidDeck-Proton-captures/` → tarball on Download.

**Pitfalls:** do not `cp -a` all of `/tmp/wow-launch` (huge `bnet-launch.log`). After exit, guest is down — capture **before** leaving the session or pull from `/sdcard/Download/*.tar.gz`.

## Proven paths (2026-10-24)

See `device/captures/RESULTS.md`.
