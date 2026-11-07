#!/usr/bin/env python3
"""Append the Samsung bootloader markers that LineageOS adds for gtowifi (device/samsung/gtowifi/mkbootimg.mk):
   'SEANDROIDENFORCE' (16 bytes) + a fake 'SignerVer02' struct (16 + 496 = 512 bytes), then zero-pad to 4096.
   Usage: samsung-sign-boot.py in.img out.img"""
import sys
src, dst = sys.argv[1], sys.argv[2]
d = open(src, "rb").read()
assert d[:8] == b"ANDROID!", "not an Android boot image"
assert len(d) % 2048 == 0, "image must end on a page (2048) boundary so the markers follow it directly"
assert not d.endswith(b"SEANDROIDENFORCE"), "already marked"
d += b"SEANDROIDENFORCE"
d += b"SignerVer02" + b"\0" * 5 + b"\0" * 496
d += b"\0" * (-len(d) % 4096)
open(dst, "wb").write(d)
print(dst, len(d), "bytes")
