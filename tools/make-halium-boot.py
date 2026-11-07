#!/usr/bin/env python3
"""Build a flashable gtowifi boot partition image by swapping the kernel in a known-good one.

Keeps everything else from the template (ramdisk, cmdline, header os_version/SPL, load addresses, board name),
then appends the Samsung trailer (SEANDROIDENFORCE + fake SignerVer02, no padding) and the unsigned AVB hash
footer (salt = sha256(kernel), prop com.android.build.boot.os_version=15), exactly as for boot-halium-vt.img.

Before building, it rebuilds the template from its own kernel and checks that the result is byte-identical,
so the recipe is proven on every run.

Usage: make-halium-boot.py TEMPLATE.img KERNEL_SOURCE OUT.img
  KERNEL_SOURCE: a raw kernel (Image.gz-dtb) or a boot image (e.g. halium-boot.img) whose kernel is used.
"""
import hashlib, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkboot_v1, avb_footer

PART_SIZE = 64 * 1024 * 1024
TRAILER = b"SEANDROIDENFORCE" + b"SignerVer02" + b"\0" * 5 + b"\0" * 496


def make(t, kernel):
    img = mkboot_v1.build(kernel, t["ramdisk"], t["cmdline"], t["os_version"], name=t["name"].split(b"\0")[0],
                          page=t["page_size"], kernel_addr=t["kernel_addr"], ramdisk_addr=t["ramdisk_addr"],
                          tags_addr=t["tags_addr"]) + TRAILER
    return avb_footer.add_hash_footer(img, PART_SIZE, "boot", hashlib.sha256(kernel).hexdigest(),
                                      props=[("com.android.build.boot.os_version", "15")])


def main():
    tmpl_path, ksrc, out = sys.argv[1:4]
    tmpl = open(tmpl_path, "rb").read()
    t = mkboot_v1.extract(tmpl_path)
    if make(t, t["kernel"]) != tmpl:
        sys.exit("ABORT: rebuilding the template from its own parts is not byte-identical; recipe differs")
    print("recipe check: template rebuilt byte-identical")

    kb = open(ksrc, "rb").read()
    kernel = mkboot_v1.extract(ksrc)["kernel"] if kb[:8] == b"ANDROID!" else kb
    new = make(t, kernel)
    open(out, "wb").write(new)
    print("kernel  old %d bytes sha256 %s" % (len(t["kernel"]), hashlib.sha256(t["kernel"]).hexdigest()[:16]))
    print("kernel  new %d bytes sha256 %s" % (len(kernel), hashlib.sha256(kernel).hexdigest()[:16]))
    print("cmdline", t["cmdline"].decode())
    print("wrote", out, len(new), "bytes sha256", hashlib.sha256(new).hexdigest())


if __name__ == "__main__":
    main()
