#!/usr/bin/env bash
# Pull Steam/Bnet/WoW logs after a DroidDeck Steam run (ADB agent).
# Usage: ./device/scripts/capture-tier8-steam-run.sh [tag]
set -euo pipefail
SERIAL="${ADB_SERIAL:-912601210098}"
TAG="${1:-steam-run-$(date +%Y%m%dT%H%M%S)}"
_DEVICE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CAPTURE_DEST:-$_DEVICE_ROOT/captures/$TAG}"
mkdir -p "$DEST/meta"

python3 - "$SERIAL" "$TAG" "$DEST" <<'PY'
import base64, json, subprocess, sys, tarfile, os, pathlib
serial, tag, dest = sys.argv[1:4]
AUTHORITY = "content://com.droiddeck.launcher.agent"
TOOL_NAME = os.environ.get(
    "CAPTURE_PROTON_TOOL",
    "DroidDeck-Proton 11-11.1 ARM64EC WoW",
)

def call(method, request=None, timeout=300):
    cmd = ["adb", "-s", serial, "shell", "content", "call", "--uri", AUTHORITY, "--method", method]
    if request is not None:
        enc = base64.b64encode(json.dumps(request, separators=(",", ":")).encode()).decode()
        cmd += ["--extra", f"request:s:{enc}"]
    r = subprocess.run(cmd, capture_output=True, timeout=timeout)
    out = (r.stdout + r.stderr).decode(errors="replace")
    i = out.find("json=")
    if i < 0:
        raise SystemExit(f"agent error: {out[:2000]}")
    return json.JSONDecoder().raw_decode(out[i + 5 :].lstrip())[0]

def gtext(resp):
    o = resp.get("stdout") or {}
    return o.get("text", "") if isinstance(o, dict) else str(o)

state = call("state")
log_dir = (state.get("session") or {}).get("logDir", "")
pathlib.Path(dest, "meta", "agent-state.json").write_text(json.dumps(state, indent=2))

bundle = rf'''
set -euo pipefail
TAG="{tag}"
CAP="/root/Storage/DroidDeck-Proton-captures/$TAG"
ST=/root/.local/share/Steam
BNET_PFX="$ST/steamapps/compatdata/4153382437/pfx"
WOW_PFX="$ST/steamapps/compatdata/2980947332/pfx"
TOOL="$ST/compatibilitytools.d/{TOOL_NAME}"
mkdir -p "$CAP"/{{meta,steam,bnet,wow,launch}}

echo "$TAG" > "$CAP/meta/run_tag.txt"
date -Iseconds > "$CAP/meta/captured_at.txt"
head -1 "$ST/steamapps/compatdata/4153382437/config_info" > "$CAP/meta/proton_tool_bnet.txt" 2>/dev/null || true
head -1 "$ST/steamapps/compatdata/2980947332/config_info" > "$CAP/meta/proton_tool_wow_shortcut.txt" 2>/dev/null || true
[ -f "$TOOL/version" ] && cat "$TOOL/version" > "$CAP/meta/proton_version.txt"
for f in "$TOOL/files/lib/wine/aarch64-unix/ntdll.so" "$TOOL/files/lib/wine/aarch64-windows/ntdll.dll"; do
  [ -f "$f" ] && sha256sum "$f" >> "$CAP/meta/ntdll.sha256"
done

DDLOG="{log_dir}"
if [ -n "$DDLOG" ] && [ -f "$DDLOG/session.log" ]; then
  cp -a "$DDLOG/session.log" "$CAP/meta/"
  [ -f "$DDLOG/events.jsonl" ] && cp -a "$DDLOG/events.jsonl" "$CAP/meta/"
  echo "SESSION_LOG=$DDLOG/session.log" > "$CAP/meta/paths.txt"
fi
grep -c virtual_setup_exception "$CAP/meta/session.log" 2>/dev/null > "$CAP/meta/virtual_setup_exception.count" || echo 0 > "$CAP/meta/virtual_setup_exception.count"

for f in compat_log.txt console_log.txt gameprocess_log.txt; do
  [ -f "$ST/logs/$f" ] && tail -n 500 "$ST/logs/$f" > "$CAP/steam/${{f%.txt}}-tail.txt"
done
grep -E '4153382437|2980947332|StartSession|Command prefix|Mapping AppID' "$ST/logs/compat_log.txt" 2>/dev/null | tail -n 300 > "$CAP/steam/compat_log-snippet.txt" || true

mkdir -p "$CAP/launch/bnet-latest"
if [ -d /tmp/wow-launch/bnet-latest ]; then
  for f in launch-meta.txt stamper.log wine.log; do
    [ -f /tmp/wow-launch/bnet-latest/"$f" ] && cp -a /tmp/wow-launch/bnet-latest/"$f" "$CAP/launch/bnet-latest/" || true
  done
  [ -f /tmp/wow-launch/bnet-latest/bnet-launch.log ] && tail -n 2000 /tmp/wow-launch/bnet-latest/bnet-launch.log > "$CAP/launch/bnet-latest/bnet-launch.log.tail"
fi

BLOG="$BNET_PFX/drive_c/users/steamuser/AppData/Local/Battle.net/Logs"
ls -lt "$BLOG" 2>/dev/null | head -20 > "$CAP/bnet/log-dir-ls.txt" || true
for pat in battle.net libcef agent; do
  f=$(ls -t "$BLOG"/${{pat}}-*.log 2>/dev/null | head -1)
  [ -n "$f" ] && cp -a "$f" "$CAP/bnet/" || true
done

copy_wow_logs() {{
  local root="$1" label="$2"
  [ -d "$root" ] || return 0
  find "$root" \( -name gx.log -o -name Client.log -o -name Connection.log -o -name General.log \) 2>/dev/null | while read -r L; do
    rel="${{L#"$root"/}}"
    mkdir -p "$CAP/wow/$label/$(dirname "$rel")"
    cp -a "$L" "$CAP/wow/$label/$rel"
  done
}}
copy_wow_logs "$BNET_PFX/drive_c/Program Files (x86)/World of Warcraft" bnet-prefix
copy_wow_logs "/root/Storage/Game" storage-game
copy_wow_logs "$WOW_PFX/drive_c/Program Files (x86)/World of Warcraft" wow-shortcut-prefix

{{
  ps -eo args | grep -E 'Battle.net|WowB-ARM64' | grep -v grep || echo none
  cat /tmp/wow-launch/bnet-latest/launch-meta.txt 2>/dev/null || true
}} > "$CAP/meta/runtime-evidence.txt"

tar -C /root/Storage/DroidDeck-Proton-captures -czf "/root/Storage/Download/${{TAG}}-capture.tar.gz" "$TAG"
ls -lh "/root/Storage/Download/${{TAG}}-capture.tar.gz"
'''
bundle = bundle.replace("{log_dir}", log_dir.replace('"', '\\"'))

resp = call("guest", {"argv": ["bash", "-lc", bundle], "timeout": 240, "env": {}})
print(gtext(resp))
if resp.get("exitCode") not in (0, None):
    raise SystemExit(resp.get("exitCode"))

local_tgz = os.path.join(dest, f"{tag}-capture.tar.gz")
for remote in (
    f"/sdcard/Download/{tag}-capture.tar.gz",
    f"/root/Storage/Download/{tag}-capture.tar.gz",
):
    r = subprocess.run(["adb", "-s", serial, "pull", remote, local_tgz], capture_output=True)
    if r.returncode == 0:
        break
else:
    raise SystemExit("adb pull failed for tarball")

with tarfile.open(local_tgz, "r:gz") as tf:
    tf.extractall(dest)
print(f"Saved under {dest}")
PY

echo "Capture ready: $DEST"
