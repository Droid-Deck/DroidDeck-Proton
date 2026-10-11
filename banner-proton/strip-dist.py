#!/usr/bin/env python3
# Strip a Proton dist tree: ELF with "strip --strip-unneeded", PE with "llvm-strip --strip-unneeded".
# Upstream prebuilt payloads (wine-mono, wine-gecko, Xalia) and anything that is not ELF/PE are left alone,
# except wine-mono's separate debug-symbol files (*.dbg, *.pdb), which are deleted: nothing loads them at
# run time (libmono-2.0-x86{,_64}.dbg alone are ~37 MB).
# Usage: strip-dist.py <dist dir> <elf strip tool> <pe strip tool>
import os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

root, elf_strip, pe_strip = sys.argv[1:4]
SKIP_DIRS = ("share/wine/mono", "share/wine/gecko", "share/xalia", "protonfixes")
SKIP_EXT = (".a", ".o", ".lib", ".la")

def kind(path):
    try:
        with open(path, "rb") as f:
            head = f.read(4)
    except OSError:
        return None
    if head == b"\x7fELF":
        return "elf"
    if head[:2] == b"MZ":
        return "pe"
    return None

MONO_DIR = "share/wine/mono"
MONO_DEBUG_EXT = (".dbg", ".pdb")

mono_removed = []
for dirpath, dirnames, filenames in os.walk(os.path.join(root, MONO_DIR)):
    for name in filenames:
        p = os.path.join(dirpath, name)
        if name.lower().endswith(MONO_DEBUG_EXT):
            mono_removed.append((os.path.relpath(p, root), os.lstat(p).st_size))
            os.remove(p)
for rel, size in sorted(mono_removed):
    print(f"removed {rel} ({size} bytes)")
print(f"wine-mono debug files: {len(mono_removed)} removed, {sum(s for _, s in mono_removed)} bytes "
      f"({sum(s for _, s in mono_removed)/1048576:.1f} MiB) saved")

jobs = []
for dirpath, dirnames, filenames in os.walk(root):
    rel = os.path.relpath(dirpath, root)
    if any(rel == d or rel.startswith(d + "/") or ("/" + d + "/") in ("/" + rel + "/") for d in SKIP_DIRS):
        dirnames[:] = []
        continue
    for name in filenames:
        p = os.path.join(dirpath, name)
        if os.path.islink(p) or name.endswith(SKIP_EXT):
            continue
        k = kind(p)
        if k:
            jobs.append((k, p))

def run(job):
    k, p = job
    before = os.path.getsize(p)
    tool = elf_strip if k == "elf" else pe_strip
    r = subprocess.run([tool, "--strip-unneeded", p], capture_output=True, text=True)
    return k, p, before, os.path.getsize(p), r.returncode, r.stderr.strip()

stats = {"elf": [0, 0, 0], "pe": [0, 0, 0]}
failed = []
with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
    for k, p, before, after, rc, err in ex.map(run, jobs):
        s = stats[k]
        s[0] += 1; s[1] += before; s[2] += after
        if rc:
            failed.append(f"{p}: {err}")
for k, (n, b, a) in stats.items():
    print(f"{k}: {n} files, {b/1048576:.1f} MiB -> {a/1048576:.1f} MiB")
if failed:
    print(f"{len(failed)} files could not be stripped (left as they were):")
    print("\n".join(failed[:50]))
