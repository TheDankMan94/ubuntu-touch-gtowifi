#!/usr/bin/env python3
"""Minimal AVB 1.0 'add_hash_footer' (unsigned, algorithm NONE), matching avbtool's layout.
   add_hash_footer(image_bytes, partition_size, partition_name, salt_hex, props=[]) -> partition image bytes"""
import struct, hashlib
def _pad(b, n): return b + b"\0" * (-len(b) % n)
def hash_descriptor(name, image, salt):
    digest = hashlib.sha256(salt + image).digest()
    body = struct.pack(">Q32sIIII60s", len(image), b"sha256", len(name), len(salt), len(digest), 0, b"")
    body += name.encode() + salt + digest
    body = _pad(body, 8)
    return struct.pack(">QQ", 2, len(body)) + body
def prop_descriptor(k, v):
    body = struct.pack(">QQ", len(k), len(v)) + k.encode() + b"\0" + v.encode() + b"\0"
    body = _pad(body, 8)
    return struct.pack(">QQ", 0, len(body)) + body
def add_hash_footer(image, partition_size, name, salt_hex, props=(), release=b"avbtool 1.1.0"):
    salt = bytes.fromhex(salt_hex)
    descs = b"".join(prop_descriptor(k, v) for k, v in props) + hash_descriptor(name, image, salt)
    aux = _pad(descs, 64)
    hdr = struct.pack(">4sIIQQIQQQQQQQQQQQII48s80s", b"AVB0", 1, 0, 0, len(aux), 0,
                      0, 0, 0, 0,               # hash off/size, signature off/size
                      len(descs), 0,            # public key offset/size
                      len(descs), 0,            # public key metadata offset/size
                      0, len(descs),            # descriptors offset/size
                      0, 0, 0, release, b"")    # rollback index, flags, rollback loc, release, reserved
    assert len(hdr) == 256
    vbmeta = hdr + aux
    off = (len(image) + 4095) // 4096 * 4096
    out = bytearray(partition_size)
    out[:len(image)] = image
    out[off:off+len(vbmeta)] = vbmeta
    footer = struct.pack(">4sIIQQQ28s", b"AVBf", 1, 0, len(image), off, len(vbmeta), b"")
    out[-64:] = footer
    return bytes(out)
