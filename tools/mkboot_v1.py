#!/usr/bin/env python3
"""Tiny boot image (header v1) builder + extractor, same layout/id hashing as AOSP mkbootimg."""
import struct, hashlib
def extract(path):
    b = open(path, "rb").read()
    ks, ka, rs, ra, ss, sa, ta, pg, hv, osv = struct.unpack_from("<10I", b, 8)
    P = lambda n: (n + pg - 1)//pg*pg
    k0 = pg; r0 = k0 + P(ks)
    return dict(kernel=b[k0:k0+ks], ramdisk=b[r0:r0+rs], page_size=pg, os_version=osv,
                kernel_addr=ka, ramdisk_addr=ra, tags_addr=ta, name=b[48:64],
                cmdline=b[64:576].split(b"\0")[0] + b[608:1632].split(b"\0")[0])
def build(kernel, ramdisk, cmdline, os_version, name=b"SRPSB22C003", page=2048,
          kernel_addr=0x80008000, ramdisk_addr=0x82000000, tags_addr=0x81e00000):
    sha = hashlib.sha1()
    for blob in (kernel, ramdisk, b"", b"", b""):   # kernel, ramdisk, second, dt, recovery_dtbo (Lineage 16 mkbootimg order)
        sha.update(blob); sha.update(struct.pack("<I", len(blob)))
    c1, c2 = cmdline[:511], cmdline[511:]
    hdr = struct.pack("<8s10I16s512s32s1024sIQI", b"ANDROID!", len(kernel), kernel_addr, len(ramdisk), ramdisk_addr,
                      0, 0, tags_addr, page, 1, os_version, name, c1, sha.digest(), c2, 0, 0, 1648)
    pad = lambda x: x + b"\0" * (-len(x) % page)
    return pad(hdr) + pad(kernel) + pad(ramdisk)
