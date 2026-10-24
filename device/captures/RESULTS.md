# WoW + Battle.net device results (11-11.1 ARM64EC WoW patch)

Build: **DroidDeck-Proton 11-11.1 ARM64EC WoW** (`ntdll.so` `df9bf9b386e916832eed486be8ce4dccaf68b7d6d4fa765ea7e86955be3dff75`).

| Path | Bnet | WoW Classic Era |
|------|------|-----------------|
| Steam + `Launch-BattleNet.sh` on app **4153382437** | Login, Play | In-world, D3D11 OK (`gx.log` Dx11 device create) |
| DroidDeck card `droiddeck-proton-run --app 4153382437` | Login, Play | In-world, playable (user confirmed) |

**Not used:** `steam -applaunch 4153382437` (AppError_9 / wrong app mapping).

**Bisect note:** stock **11-11.1** Bnet OK; **tier8-0001**-style builds hung WoW after DX11. Full **11-11.1 ARM64EC WoW** game patch fixes the WoW path.

Bulky capture tarballs live under `device/captures/<tag>/` locally (gitignored). Historical copies may still exist on the phone under `/sdcard/Download/`.
