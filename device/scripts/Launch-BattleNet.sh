#!/bin/bash
# Battle.net Steam shortcut: gamescope stamper + Proton (tier-8 compat tool).
#
# Steam: .exe target, launch options /usr/local/bin/Launch-BattleNet.sh %command%
# Optional env: /usr/local/etc/wow-forever.env (BNET_DIR, WOW_ROOT, FEX_*, WOW_LOGDIR)
set -uo pipefail

ENV_FILE="${WOW_ENV:-/usr/local/etc/wow-forever.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

APPID="${SteamAppId:-${SteamGameId:-${BNET_APPID:-}}}"
if [[ "$APPID" == "0" || -z "$APPID" || ${#APPID} -gt 10 ]]; then
  APPID="${BNET_APPID:-}"
fi
if [[ -z "$APPID" ]]; then
  echo "Launch-BattleNet: launch from Steam or set BNET_APPID" >&2
  exit 1
fi

LOGROOT="${WOW_LOGDIR:-/tmp/wow-launch-${APPID}}"
SESSION="$(date +%Y%m%dT%H%M%S)-$$"
LOGDIR="$LOGROOT/bnet-$SESSION"
LOG="$LOGDIR/bnet-launch.log"
WINELOG="$LOGDIR/wine.log"
META="$LOGDIR/launch-meta.txt"
mkdir -p "$LOGDIR"
ln -sfn "bnet-$SESSION" "$LOGROOT/bnet-latest" 2>/dev/null || true

exec >>"$LOG" 2>&1
echo "======== $(date -Iseconds) pid=$$ session=$SESSION ========"
echo "logdir=$LOGDIR"
echo "steam_argv=$*"
echo "env_file=$ENV_FILE wow_logdir=${WOW_LOGDIR:-unset}"

STAMPER="${WOW_STAMPER:-$(command -v droiddeck-steamgame-stamp.sh 2>/dev/null || echo /usr/local/bin/droiddeck-steamgame-stamp.sh)}"
DPY="${DISPLAY:-${STEAM_DISPLAY:-:1}}"

start_stamper() {
  # Do not honor WOW_NO_STAMPER here — WoW sets that in wow-forever-storage.env for stamper-wrap.
  if [[ -n "${BNET_NO_STAMPER:-}" ]]; then
    echo "stamper skipped (BNET_NO_STAMPER)"
    return 0
  fi
  if [[ -x "$STAMPER" ]]; then
    "$STAMPER" "$APPID" $$ "$DPY" >>"$LOGDIR/stamper.log" 2>&1 &
    echo "stamper pid $! -> $LOGDIR/stamper.log"
  else
    echo "Launch-BattleNet: warning: no stamper at $STAMPER"
  fi
}
start_stamper

STEAM_ROOT="${STEAM_COMPAT_CLIENT_INSTALL_PATH:-${WOW_STEAM_ROOT:-${HOME:-/root}/.local/share/Steam}}"
PREFIX="${STEAM_COMPAT_DATA_PATH:-${WOW_PREFIX:-}}"
if [[ -z "$PREFIX" ]]; then
  PREFIX="$STEAM_ROOT/steamapps/compatdata/$APPID"
fi

find_bnet() {
  local d
  if [[ -n "${BNET_DIR:-}" && -f "${BNET_DIR}/Battle.net Launcher.exe" ]]; then
    printf '%s\n' "$BNET_DIR"
    return 0
  fi
  for d in /root/Storage/Battle.net \
           "$PREFIX/pfx/drive_c/Program Files (x86)/Battle.net" \
           "$PREFIX/pfx/drive_c/Program Files/Battle.net"; do
    if [[ -f "$d/Battle.net Launcher.exe" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  return 1
}

find_tool() {
  local p
  if [[ -n "${STEAM_COMPAT_TOOL_PATHS:-}" ]]; then
    p="${STEAM_COMPAT_TOOL_PATHS%%:*}"
    if [[ -x "$p/droiddeck-proton-wrap" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  fi
  if [[ -n "${WOW_PROTON_DIR:-}" && -x "${WOW_PROTON_DIR}/droiddeck-proton-wrap" ]]; then
    printf '%s\n' "$WOW_PROTON_DIR"
    return 0
  fi
  return 1
}

BNET="$(find_bnet)" || { echo "Launch-BattleNet: Battle.net Launcher.exe not found (set BNET_DIR)"; exit 1; }
EXE="$BNET/Battle.net Launcher.exe"

TOOL="$(find_tool)" || {
  echo "Launch-BattleNet: set Compatibility tool on this shortcut in Steam (DroidDeck)"
  exit 1
}
PROTON="$TOOL/droiddeck-proton-wrap"

ICD="${VK_ICD_FILENAMES:-${VK_DRIVER_FILES:-${BL_VK_DRIVER:-}}}"
ICD="${ICD%%:*}"

{
  echo "session=$SESSION"
  echo "appid=$APPID"
  echo "prefix=$PREFIX"
  echo "tool=$TOOL"
  echo "bnet=$BNET"
  echo "exe=$EXE"
  echo "stamper=$STAMPER"
  echo "session-icd=$ICD"
  echo "steam_compat_data=${STEAM_COMPAT_DATA_PATH:-unset}"
  echo "steam_compat_tool_paths=${STEAM_COMPAT_TOOL_PATHS:-unset}"
  if [[ -f "$PREFIX/config_info" ]]; then
    echo "config_info=$(head -1 "$PREFIX/config_info")"
  fi
  if [[ -f "$TOOL/version" ]]; then
    echo "proton_version=$(cat "$TOOL/version")"
  fi
  for f in \
    "$TOOL/files/lib/wine/aarch64-unix/ntdll.so" \
    "$TOOL/files/lib/wine/aarch64-windows/ntdll.dll"; do
    if [[ -f "$f" ]]; then
      echo "sha256 $(sha256sum "$f")"
    fi
  done
} >"$META"

echo "appid=$APPID prefix=$PREFIX tool=$TOOL bnet=$BNET stamper=$STAMPER"
echo "session-icd=$ICD steam_compat_data=${STEAM_COMPAT_DATA_PATH:-unset}"
cat "$META" | sed 's/^/meta /'

for f in "$PROTON" "$EXE"; do
  if [[ ! -e "$f" ]]; then echo "Launch-BattleNet: missing $f"; exit 1; fi
done
if [[ -z "$ICD" || ! -r "$ICD" ]]; then
  echo "Launch-BattleNet: no session Vulkan ICD (pick a driver in DroidDeck)"
  exit 1
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
export STEAM_COMPAT_DATA_PATH="$PREFIX"
export SteamAppId="$APPID"
export SteamGameId="${SteamGameId:-$APPID}"
if [[ -z "${VK_ICD_FILENAMES:-}" && -z "${VK_DRIVER_FILES:-}" ]]; then
  export VK_ICD_FILENAMES="$ICD"
  export VK_DRIVER_FILES="$ICD"
fi

pre="${LD_PRELOAD:-}"
pre="${pre//\/root\/.steam\/bin32\/gameoverlayrenderer.so/}"
pre="${pre##:}"; pre="${pre%%:}"
export LD_PRELOAD="${pre:-}"

if [[ -n "${FEX_APP_DATA_LOCATION:-}" ]]; then
  mkdir -p "$FEX_APP_DATA_LOCATION"
  export FEX_APP_DATA_LOCATION
fi
[[ -n "${FEX_BNET_FORCE_X86:-}" ]] && export FEX_BNET_FORCE_X86
[[ -n "${FEX_DYNAMICL1CACHE:-}" ]] && export FEX_DYNAMICL1CACHE

WOW_ROOT="${WOW_ROOT:-}"
if [[ -n "$WOW_ROOT" && -d "$WOW_ROOT" ]]; then
  PF86="$PREFIX/pfx/drive_c/Program Files (x86)"
  if [[ -d "$PF86" && ! -e "$PF86/World of Warcraft" ]]; then
    ln -s "$WOW_ROOT" "$PF86/World of Warcraft"
    echo "linked Program Files (x86)/World of Warcraft -> $WOW_ROOT"
  fi
fi

export PROTON_LOG="${BNET_PROTON_LOG:-${WOW_PROTON_LOG:-1}}"
export PROTON_LOG_DIR="$LOGDIR"
export WINEDEBUG="${BNET_WINEDEBUG:-${WOW_WINEDEBUG:-+timestamp,+pid,+tid,+err,+loaddll,+seh}}"
: >"$WINELOG"
echo "PROTON_LOG=$PROTON_LOG PROTON_LOG_DIR=$PROTON_LOG_DIR WINEDEBUG=$WINEDEBUG WINELOG=$WINELOG"
echo "LD_PRELOAD=${LD_PRELOAD:-} FEX_APP_DATA_LOCATION=${FEX_APP_DATA_LOCATION:-} FEX_BNET_FORCE_X86=${FEX_BNET_FORCE_X86:-} FEX_DYNAMICL1CACHE=${FEX_DYNAMICL1CACHE:-}"

snapshot_bnet_logs() {
  local blog="$PREFIX/pfx/drive_c/users/steamuser/AppData/Local/Battle.net/Logs"
  echo "---- Battle.net client logs ($blog) ----"
  if [[ ! -d "$blog" ]]; then
    echo "(no log dir yet)"
    return 0
  fi
  ls -lt "$blog" 2>/dev/null | head -12 || true
  local f
  for f in "$blog"/battle.net-*.log "$blog"/libcef-*.log "$blog"/agent-*.log; do
    [[ -f "$f" ]] || continue
    echo "== tail ${f##*/} ($(stat -c '%s bytes %y' "$f" 2>/dev/null || echo ?)) =="
    tail -n 25 "$f" || true
  done
}

trap 'snapshot_bnet_logs; echo "Launch-BattleNet trap exit $?"' EXIT

cd "$BNET" || exit 1
echo "exec proton waitforexitandrun $EXE"
(
  export WINEDEBUG="$WINEDEBUG"
  "$PROTON" waitforexitandrun "$EXE"
) 2>>"$WINELOG"
rc=$?
trap - EXIT
snapshot_bnet_logs
echo "proton-exit $rc wine-log-bytes=$(stat -c '%s' "$WINELOG" 2>/dev/null || echo 0)"
if [[ -s "$WINELOG" ]]; then
  echo "---- wine.log tail ----"
  tail -n 40 "$WINELOG" || true
fi
exit "$rc"
