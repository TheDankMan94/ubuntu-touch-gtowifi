#!/usr/bin/env python3
"""Compare Android boot images field by field (header v1, Samsung trailer, AVB footer/vbmeta)."""
import sys, struct, hashlib
def vbmeta(b, off=0):
    h = b[off:off+256]
    if h[:4] != b"AVB0": return {"vbmeta": "none"}
    (maj, mnr, auth, aux, alg) = struct.unpack_from(">IIQQI", h, 4)
    (desc_off, desc_size, rb, flags, rbloc) = struct.unpack_from(">QQQII", h, 96)
    pk_off, pk_size = struct.unpack_from(">QQ", h, 64)
    rel = h[128:176].split(b"\0")[0].decode()
    r = {"libavb": f"{maj}.{mnr}", "algorithm": alg, "auth_block": auth, "aux_block": aux, "pubkey_size": pk_size,
         "rollback_index": rb, "flags": flags, "rollback_loc": rbloc, "release": rel, "descriptors": []}
    p = off + 256 + auth + desc_off; end = p + desc_size
    while p < end:
        tag, n = struct.unpack_from(">QQ", b, p); body = b[p+16:p+16+n]
        if tag == 2:
            size, = struct.unpack_from(">Q", body, 0); alg_s = body[8:40].split(b"\0")[0].decode()
            nl, sl, dl, fl = struct.unpack_from(">IIII", body, 40); q = 40+16+60
            name = body[q:q+nl].decode(); dig = body[q+nl+sl:q+nl+sl+dl].hex()
            r["descriptors"].append(f"hash {name} size={size} {alg_s} digest={dig[:16]}.. flags={fl}")
        elif tag == 4:
            loc, nl, kl = struct.unpack_from(">III", body, 0)
            r["descriptors"].append(f"chain {body[76:76+nl].decode()} rb_loc={loc} key={kl}B")
        elif tag == 0:
            kl, vl = struct.unpack_from(">QQ", body, 0)
            r["descriptors"].append(f"prop {body[16:16+kl].decode()}={body[17+kl:17+kl+vl][:60]}")
        else:
            r["descriptors"].append(f"tag{tag} {n}B")
        p += 16 + n
    return r
def boot(path):
    b = open(path, "rb").read(); r = {"file": path, "size": len(b)}
    f = struct.unpack_from("<8sIIIIIIIIII", b, 0)
    r.update(dict(zip(["magic","kernel_size","kernel_addr","ramdisk_size","ramdisk_addr","second_size","second_addr","tags_addr","page_size","header_version","os_version"], f)))
    v = r["os_version"]
    r["os"] = f"{(v>>25)&127}.{(v>>18)&127}.{(v>>11)&127} spl={((v>>4)&127)+2000}-{v&15:02d}"
    r["name"] = b[48:64].split(b"\0")[0]
    r["cmdline"] = (b[64:576].split(b"\0")[0] + b[608:1632].split(b"\0")[0]).decode()
    r["recovery_dtbo_size"], r["recovery_dtbo_offset"], r["header_size"] = struct.unpack_from("<IQI", b, 1632)
    pg = r["page_size"]; P = lambda n: (n + pg - 1)//pg*pg
    endimg = pg + P(r["kernel_size"]) + P(r["ramdisk_size"]) + P(r["second_size"]) + P(r["recovery_dtbo_size"])
    r["image_end"] = endimg
    r["trailer@end"] = b[endimg:endimg+32]
    i = b.find(b"SEANDROIDENFORCE"); r["SEANDROIDENFORCE_at"] = i
    j = b.find(b"SignerVer02"); r["SignerVer02_at"] = j
    if j >= 0: r["signer_block_nonzero_bytes"] = sum(1 for x in b[j+11:j+512] if x)
    k = b[pg:pg+P(r["kernel_size"])]
    r["kernel_is_gzip"] = k[:2] == b"\x1f\x8b"
    r["dtb_count_in_kernel"] = k.count(b"\xd0\x0d\xfe\xed")
    if b[-64:-60] == b"AVBf":
        maj, mnr, orig, vbo, vbs = struct.unpack_from(">IIQQQ", b, len(b)-60)
        r["avb_footer"] = f"v{maj}.{mnr} original_size={orig} vbmeta@{vbo} ({vbs}B)"
        r["vbmeta"] = vbmeta(b, vbo)
    else:
        r["avb_footer"] = "none"
    return r
if __name__ == "__main__":
    A, B = boot(sys.argv[1]), boot(sys.argv[2])
    for k in A:
        if k == "file": continue
        same = "   " if A.get(k) == B.get(k) else "!! "
        print(f"{same}{k}:\n      lineage: {A.get(k)}\n      ours   : {B.get(k)}")
    if len(sys.argv) > 3:
        print("\n== vbmeta partition image:", sys.argv[3]); print(vbmeta(open(sys.argv[3],"rb").read()))
