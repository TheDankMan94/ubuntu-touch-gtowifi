#!/usr/bin/env bash
# Runs INSIDE the build container (via ./build-env.sh run "./halium-build.sh <step>").
# Steps:
#   boot     kernel + halium-boot.img           (first target; fastest way to find kernel/device errors)
#   system   system.img (+ vendor.img if the device builds one)
#   all      boot, then system
# Logs go to /work/logs/<step>.log so they can be read from the host.
set -uo pipefail

STEP="${1:-boot}"
JOBS="${JOBS:-$(nproc)}"
cd /work/halium
mkdir -p /work/logs

export LC_ALL=C
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/work/.ccache
ccache -M 40G >/dev/null 2>&1 || true

# envsetup reads LineageOS's lunch list from GitHub (vendor/lineage/vendorsetup.sh); harmless.
set +u
source build/envsetup.sh
lunch lineage_gtowifi-userdebug || { echo "LUNCH FAILED"; exit 1; }
set -u

run() {
  local name="$1"; shift
  echo "=== $name: make -j$JOBS $* ($(date))"
  make -j"$JOBS" "$@" 2>&1 | tee "/work/logs/$name.log"
  local rc=${PIPESTATUS[0]}
  echo "=== $name finished with exit code $rc ($(date))" | tee -a "/work/logs/$name.log"
  return $rc
}

case "$STEP" in
  boot)   run boot halium-boot ;;
  # vendorimage is built too: the tablet's current vendor partition is LineageOS 22.2 (Android 15)
  # and cannot be reused under an Android 9 Halium system.
  system) run system systemimage vendorimage ;;
  all)    run boot halium-boot && run system systemimage vendorimage ;;
  mods)   shift; run mods "$@" ;;
  *)      echo "usage: $0 {boot|system|all|mods <targets...>}" >&2; exit 2 ;;
esac
