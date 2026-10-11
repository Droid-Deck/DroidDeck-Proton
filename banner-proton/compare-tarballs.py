#!/usr/bin/env python3
# Compare two Proton tarballs by entry: path (without the top directory), type, mode, size and
# symlink target. Prints the differences; exits 0 either way (the caller decides what matters).
# Usage: compare-tarballs.py <old.tar.gz> <new.tar.gz>
import hashlib, re, sys, tarfile

# The default prefix's Windows Installer cache file gets a random name in every build.
RANDOM = re.compile(r'^files/share/default_pfx[^/]*/drive_c/windows/Installer/[0-9a-f]+\.msi$')

def entries(path):
    out = {}
    with tarfile.open(path) as t:
        for m in t:
            name = m.name.split('/', 1)[1] if '/' in m.name else ''
            if RANDOM.match(name):
                name = re.sub(r'[0-9a-f]+\.msi$', '<random>.msi', name)
            kind = 'd' if m.isdir() else 'l' if m.issym() else 'h' if m.islnk() else 'f'
            digest = hashlib.sha256(t.extractfile(m).read()).hexdigest()[:16] if kind == 'f' else ''
            out[name] = (kind, oct(m.mode), m.size if kind == 'f' else 0, m.linkname, digest)
    return out

old, new = entries(sys.argv[1]), entries(sys.argv[2])
only_old = sorted(set(old) - set(new))
only_new = sorted(set(new) - set(old))
changed = sorted(p for p in set(old) & set(new) if old[p][:4] != new[p][:4])
size_only = [p for p in changed if old[p][:2] == new[p][:2] and old[p][3] == new[p][3]]
other = [p for p in changed if p not in size_only]
content = sorted(p for p in set(old) & set(new) if p not in changed and old[p][4] != new[p][4])

print(f'entries: old {len(old)}, new {len(new)}')
print(f'only in old ({len(only_old)}):'); [print('  ' + p) for p in only_old]
print(f'only in new ({len(only_new)}):'); [print('  ' + p) for p in only_new]
print(f'type/mode/link differs ({len(other)}):')
for p in other:
    print(f'  {p}: {old[p]} -> {new[p]}')
print(f'size differs ({len(size_only)}):')
for p in size_only:
    print(f'  {p}: {old[p][2]} -> {new[p][2]} ({new[p][2] - old[p][2]:+d})')
print(f'same size, different content ({len(content)}):')
for p in content:
    print('  ' + p)
same = len(set(old) & set(new)) - len(changed) - len(content)
print(f'identical (type, mode, size, link target, sha256): {same}')

# For a few same-size files that differ, show how many bytes differ and where (timestamps differ
# in a few bytes at fixed offsets; real code changes differ in many).
def read(path, names):
    found = {}
    with tarfile.open(path) as t:
        for m in t:
            name = m.name.split('/', 1)[1] if '/' in m.name else ''
            if name in names:
                found[name] = t.extractfile(m).read()
    return found

pick = []
for prefix in ('files/lib/aarch64-linux-gnu/', 'files/lib/vkd3d/', 'files/lib/wine/aarch64-windows/',
               'files/lib/wine/i386-windows/', 'files/lib/wine/dxvk/', 'files/lib/wine/aarch64-unix/'):
    pick += [p for p in content if p.startswith(prefix)][:2]
if pick:
    a, b = read(sys.argv[1], set(pick)), read(sys.argv[2], set(pick))
    print('byte differences in samples:')
    for p in pick:
        diff = [i for i, (x, y) in enumerate(zip(a[p], b[p])) if x != y]
        print(f'  {p}: {len(diff)} bytes differ, offsets {[hex(i) for i in diff[:8]]}')
