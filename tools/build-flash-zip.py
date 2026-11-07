#!/usr/bin/env python3
"""Build a recovery-installable zip that dd's raw images to partitions and verifies by read-back.
   Usage: build-flash-zip.py out.zip name=partition=image [name=partition=image ...]
   Images must be multiples of 4096 bytes. Payloads are stored (not compressed) and 4096-aligned,
   so the update-binary can dd straight out of the zip with no unzip tool."""
import sys, zipfile, struct, hashlib, os
BS = 4096
out = sys.argv[1]
items = [a.split("=", 2) for a in sys.argv[2:]]
shas, info = {}, {}
zf = zipfile.ZipFile(out, "w", zipfile.ZIP_STORED, allowZip64=True)
for name, part, path in items:
    data = open(path, "rb").read()
    assert len(data) % BS == 0, path
    shas[name] = hashlib.sha256(data).hexdigest()
    fn = name + ".img"
    pos = zf.fp.tell(); pad = 0
    while (pos + 30 + len(fn) + 4 + pad) % BS: pad += 1
    zi = zipfile.ZipInfo(fn, (2026, 11, 6, 0, 0, 0)); zi.compress_type = zipfile.ZIP_STORED
    zi.extra = struct.pack("<HH", 0xD935, pad) + b"\0" * pad; zi.external_attr = 0o644 << 16
    zf.writestr(zi, data)
    off = pos + 30 + len(fn) + len(zi.extra); assert off % BS == 0
    info[name] = (part, off // BS, len(data) // BS)
lines = "\n".join(f"flash {n} /dev/block/bootdevice/by-name/{p} {o} {c} {shas[n]}" for n, (p, o, c) in info.items())
script = f'''#!/system/bin/sh
OUTFD=$2
ZIP=$3
ui_print() {{ echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }}
SHA=sha256sum
command -v sha256sum >/dev/null 2>&1 || SHA="toybox sha256sum"
flash() {{
  [ -e "$2" ] || {{ ui_print "ABORT: missing $2"; exit 1; }}
  ui_print "Writing $1 ..."
  dd if="$ZIP" of="$2" bs=4096 skip=$3 count=$4 2>/dev/null || {{ ui_print "ABORT: write failed ($1)"; exit 1; }}
  sync
  GOT=$(dd if="$2" bs=4096 count=$4 2>/dev/null | $SHA | cut -d" " -f1)
  if [ "$GOT" = "$5" ]; then ui_print "$1 written and verified"; else ui_print "VERIFY FAILED: $1 (got $GOT)"; exit 1; fi
}}
{lines}
ui_print "All done. Reboot the tablet."
exit 0
'''
for nm, content, mode in [("META-INF/com/google/android/update-binary", script, 0o755),
                          ("META-INF/com/google/android/updater-script", "# intentionally empty\n", 0o644)]:
    zi = zipfile.ZipInfo(nm, (2026, 11, 6, 0, 0, 0)); zi.compress_type = zipfile.ZIP_STORED; zi.external_attr = mode << 16
    zf.writestr(zi, content)
zf.close()
z = open(out, "rb"); ok = True
for n, (p, o, c) in info.items():
    z.seek(o * BS); h = hashlib.sha256(); left = c * BS
    while left:
        b = z.read(min(left, 1 << 20)); h.update(b); left -= len(b)
    ok &= h.hexdigest() == shas[n]; print(n, "->", p, "blocks", o, c, "slice ok:", h.hexdigest() == shas[n])
print("zip test:", zipfile.ZipFile(out).testzip(), "| size", os.path.getsize(out), "| all ok:", ok)
