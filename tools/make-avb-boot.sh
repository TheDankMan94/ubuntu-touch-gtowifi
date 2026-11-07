#!/usr/bin/env bash
# Runs INSIDE the build container (python2 available). Adds the AVB hash footer that LineageOS's build
# adds to gtowifi's boot image, producing a full 64 MiB boot partition image.
#   in : flash/boot-samsung.img   (halium-boot.img + SEANDROIDENFORCE + SignerVer02 block)
#   out: flash/boot-avb.img       (same + AVB hash footer, padded to the boot partition size)
set -euo pipefail
cd /work
AVB=halium/external/avb/avbtool
PART_SIZE=67108864

cp flash/boot-samsung.img flash/boot-avb.img
python2 "$AVB" add_hash_footer \
  --image flash/boot-avb.img \
  --partition_size "$PART_SIZE" \
  --partition_name boot \
  --salt "$(sha256sum halium/out/target/product/gtowifi/kernel | cut -d' ' -f1)"

ls -l flash/boot-avb.img
python2 "$AVB" info_image --image flash/boot-avb.img | tee flash/boot-avb.info.txt
echo "make-avb-boot: done"
