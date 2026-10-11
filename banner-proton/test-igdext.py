#!/usr/bin/env python3
# Check the proton script's igdext64.dll copy against a built tool tree, without running Wine.
# Takes the functions involved (file_exists, makedirs, try_copy, find_igdext_dll) from the tree's own
# "proton" script and runs the same steps as the prefix setup on a scratch prefix, for the aarch64 and
# x86_64 host PE arches, plus a tree that ships no igdext at all.
# Usage: test-igdext.py <tool dir (the folder with the proton script and files/)>
import ast, errno, os, shutil, stat, sys, tempfile, types

tool = sys.argv[1]
src = open(os.path.join(tool, "proton")).read()
wanted = {"file_exists", "makedirs", "try_copy", "find_igdext_dll"}
funcs = [n for n in ast.parse(src).body if isinstance(n, ast.FunctionDef) and n.name in wanted]
missing = wanted - {f.name for f in funcs}
if missing:
    sys.exit(f"proton script lacks {sorted(missing)}")

logs = []
ns = {"os": os, "errno": errno, "shutil": shutil, "stat": stat,
      "copyfile": shutil.copyfile, "log": logs.append}
exec(compile(ast.Module(body=funcs, type_ignores=[]), "proton", "exec"), ns)

INTC_STORE = "drive_c/windows/system32/DriverStore/FileRepository/igd_faux.inf_1"
lib_dir = os.path.join(tool, "files/lib/")
shipped = sorted(os.listdir(os.path.join(lib_dir, "wine/igdext")))
print("files/lib/wine/igdext:", shipped)

def setup_prefix(host_pe_arch, lib):
    # The prefix setup step from the proton script (CompatData.setup_prefix).
    ns["g_proton"] = types.SimpleNamespace(host_pe_arch=host_pe_arch, lib_dir=lib)
    prefix = tempfile.mkdtemp() + "/"
    del logs[:]
    dll = ns["find_igdext_dll"]()
    if dll:
        ns["makedirs"](os.path.join(prefix, INTC_STORE))
        with open(os.path.join(prefix, "tracked_files"), "w") as tracked:
            ns["try_copy"](dll, INTC_STORE, optional=True, prefix=prefix, track_file=tracked, link_debug=True)
    return dll, prefix

fail = 0
for arch in ("aarch64-windows", "x86_64-windows"):
    dll, prefix = setup_prefix(arch, lib_dir)
    out = os.path.join(prefix, INTC_STORE, "igdext64.dll")
    ok = dll is not None and os.path.isfile(out) and os.path.getsize(out) == os.path.getsize(dll) and not logs
    print(f"{'ok' if ok else 'FAIL'}: host {arch}: source {os.path.relpath(dll, tool) if dll else None}, "
          f"copied {os.path.isfile(out)}, log {logs}")
    fail |= not ok

# A tree without any igdext build: no copy, nothing logged.
dll, prefix = setup_prefix("aarch64-windows", tempfile.mkdtemp() + "/")
ok = dll is None and not os.path.exists(os.path.join(prefix, INTC_STORE)) and not logs
print(f"{'ok' if ok else 'FAIL'}: no igdext shipped: skipped, log {logs}")
fail |= not ok
sys.exit(fail)
