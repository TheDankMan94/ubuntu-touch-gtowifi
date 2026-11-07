# Ubuntu Touch (Halium 9) for the Samsung Galaxy Tab A 8.0 (2019) Wi-Fi, SM-T290 (`gtowifi`)

Work-in-progress port. The tablet (SDM429 / msm8937, Adreno 504, kernel 4.9) boots Ubuntu Touch 16.04 on a
Halium 9 (LineageOS 16.0 based) base.

## Status (tested on one SM-T290, 2026-11-06)

| Works | Not working / untested |
|---|---|
| Boot, display, touch, Wi-Fi, sound (speaker), Bluetooth, battery, buttons, sensors + auto-rotate | Camera: HAL starts and both sensors are detected (gc8034 rear, gc2375h front), but opening a camera returns a device error and the Camera app crashes |
| | Headphone jack, microphone, USB-OTG, suspend/resume, power profiles, GPS: not tested |

Nothing here has been reviewed by UBports. Treat it as a bring-up log plus the files that were needed.

## What is in this repository

- `device/samsung/gtowifi/`: Halium device tree (BoardConfig, device.mk, VINTF manifest, fstab/ueventd, audio, Wi-Fi,
  sensor and QMI config). Much of it is derived from the LineageOS `gtowifi` tree (Apache-2.0).
- `kernel/`: our changes to `LineageOS/android_kernel_samsung_sdm429` (branch `lineage-22.2`):
  `halium_gtowifi_defconfig` (Halium + Bluetooth options, merged over `lineageos_gtowifi_defconfig`) and a binder patch
  (`0001-...patch`) so HIDL calls work when AppArmor is the active LSM.
- `overlay/rootfs/`: Ubuntu Touch files that are not part of the Android side (startup job for the audio/Wi-Fi chips,
  MAC and Bluetooth address, override for a modem-only service).
- `tools/`: Docker build environment, build wrapper, and the Python scripts that turn `halium-boot.img` into an image the
  Samsung bootloader accepts (Samsung trailer, AVB hash footer, matching `os_version`).
- `notes/`: kernel config fragment, generated udev rules (from the LineageOS `ueventd.rc`), boot image comparison script.
- `docs/NOTES.md`: the full log: every problem found, its cause and fix, in order. Read this first.

## What is deliberately NOT here

- The Samsung proprietary vendor blobs (`vendor/samsung/gtowifi`). The build used the third-party
  `AndroidBlobs/vendor_samsung_gtowifi` repository; check its licence yourself before redistributing anything from it.
- Built images, the Halium/LineageOS source trees, the Ubuntu Touch rootfs, logs.
- Some fixes were applied on the tablet by hand and are only described in `docs/NOTES.md` and mirrored in the device
  tree; a full clean rebuild of `system.img`/`vendor.img` with all of them has not been done yet.

## Building (outline)

1. Set up a Halium 9 tree for `samsung/gtowifi` (see the Halium docs), copy `device/samsung/gtowifi` into it and the
   kernel files into `kernel/samsung/sdm429` (apply the patch with `patch -p1`).
2. `tools/build-env.sh` builds the Ubuntu 20.04 container; `tools/halium-build.sh boot|system|mods` builds inside it.
3. `tools/make-halium-boot.py` turns the result into a boot image for this bootloader. It needs a known-good template
   image to copy the ramdisk and command line from (see `docs/NOTES.md`, "Bring-up log").

Flashing a boot image to the wrong partition can soft-brick a device. Use at your own risk.
