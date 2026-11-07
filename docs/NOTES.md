# gtowifi (SM-T290) Halium 9 port: working notes

Last updated: 2026-11-06

## Layout
- `halium/`: Halium 9 source tree (`Halium/android`, branch `halium-9.0`, 613 projects, ~34 GB). Synced with `repo sync -c --no-tags --optimized-fetch`.
  - `kernel/samsung/sdm429`: LineageOS kernel, `lineage-22.2`, shallow clone (4.9, defconfig `lineageos_gtowifi_defconfig`).
  - `vendor/samsung/gtowifi`: stock Android 9 vendor files (AndroidBlobs, build `T290XXU1ASF7`, `PPR1.180610.011`, Sept 2019), shallow clone.
  - `device/samsung/gtowifi`: first-draft Halium device tree (AndroidProducts.mk, lineage_gtowifi.mk, BoardConfig.mk, device.mk, board-info.txt, rootdir/etc/fstab.qcom). Written from the Lineage gtowifi tree plus the Halium X00TD example. **Never built.**
  - `kernel/samsung/sdm429/arch/arm64/configs/halium_gtowifi_defconfig`: Halium fragment (24 options), merged via `TARGET_KERNEL_ADDITIONAL_CONFIG`. Every option name exists in this kernel's Kconfig. Merged config never generated (no flex/bison on host).
  - `hybris-patches` applied with `apply-patches.sh --mb` (107 patches, no errors). This adds `build/make/target/product/halium.mk`. Re-run after any `repo sync --force-sync`.
- `reference/lineage-19.1-device-gtowifi`: LineageOS device tree (oldest branch is 19.1 = Android 12). Reference only, not part of the build.
- `notes/`:
  - `running-lineage-4.9.config`: full kernel config pulled from the tablet over ADB.
  - `halium-kernel-check.plain.txt`: Halium's `check-kernel-config` output for it (14 ok, 15 to set, 46 not present in config).
  - `halium-gtowifi.config`: proposed kernel fragment. Untested.
- `Dockerfile`, `build-env.sh`: Ubuntu 20.04 build container (Android 9 needs Python 2). Image not built.
- `gtowifi-halium-feasibility.md`: feasibility report.
- `repo-sync.log`: sync log.

## Status
- Done: source sync, kernel/vendor/reference trees fetched, kernel gap list produced.
- Not done: Docker is not installed (`sudo` is blocked inside the Claude app; run
  `sudo apt-get update && sudo apt-get install -y docker.io git-lfs ccache` in a normal terminal). The user is deliberately NOT added to the `docker` group (it is effectively root); `build-env.sh` runs `sudo docker` instead, so docker steps must be run from a normal terminal. Container image, kernel build and any boot test are still to do.
- `repo` launcher is at `~/.local/bin/repo` (downloaded from storage.googleapis.com/git-repo-downloads/repo).

## Gotchas found
- `repo sync` does not accept `--fail-fast=false`; use plain `--fail-fast` or omit it.
- Repo identity: pass `GIT_AUTHOR_NAME` / `GIT_COMMITTER_NAME` and the email variants through the environment instead of editing global git config.
- Vendor files are stock Android 9; the vendor partition currently on the tablet is LineageOS 22.2's. Do not copy blobs from the tablet.
- Kernel in the tree is the Android 15-era Lineage branch of a 4.9 kernel. If it misbehaves with Halium 9 userspace, look for an older Lineage or Samsung stock kernel branch.

## Build log (2026-11-06)
`./build-env.sh run "./halium-build.sh boot"` now succeeds (1m42s incremental). Fixes needed on the way, all in `halium/device/samsung/gtowifi/BoardConfig.mk` unless noted:
1. Lineage bootanimation needs ImageMagick: placeholder `bootanimation-placeholder.zip` + `TARGET_BOOTANIMATION`.
2. Duplicate CNE modules in `vendor/samsung/gtowifi/Android.mk` (system + vendor copies): kept the vendor copies (original saved as `Android.mk.orig`).
3. Kernel rejects tree GCC 4.9 on arm64: `TARGET_KERNEL_CLANG_COMPILE := true` (tree clang 6.0.2). Do NOT set `TARGET_KERNEL_CLANG_PATH` from BoardConfig (`$(BUILD_TOP)` is empty there).
4. 32-bit vDSO link fails with the old binutils: `# CONFIG_COMPAT_VDSO is not set` in `halium_gtowifi_defconfig`.
5. In-tree `dtc` lacks `-@`: `TARGET_KERNEL_ADDITIONAL_FLAGS := DTC_EXT=<tree>/prebuilts/misc/linux-x86/dtc/dtc`.

Result: `halium/out/target/product/gtowifi/halium-boot.img` (17,100,800 bytes, sha256 a3a1e688...dbe9). Header checked by hand: kernel 0x80008000, ramdisk 0x82000000, tags 0x81e00000, page 2048, header v1, board SRPSB22C003, cmdline as in BoardConfig, fits the 64 MiB boot partition. **Never booted or flashed.** No dtbo image was produced by this target.

## System + vendor images (2026-11-06)
`./build-env.sh run "./halium-build.sh system"` succeeded (22m41s second run; first run failed at 56%). Extra fixes:
6. `TARGET_USES_GRALLOC1 := true` (display HAL otherwise needs legacy `libmemalloc`).
7. The host SignApk tool crashes (`UnsatisfiedLinkError org.conscrypt...`) on this Android 9 / Ubuntu 20.04 setup, so the 8 vendor APKs (CNEService, TimeService, ImsSettings, dpmserviceapp, qcrilmsgtunnel, ConnectionSecurityService, SSGTelemetryService, TrustZoneAccessService) were removed from `PRODUCT_PACKAGES` in `vendor/samsung/gtowifi/gtowifi-vendor.mk` (original saved as `.orig`). They are cellular/IMS/telemetry apps, not needed on a Wi-Fi tablet. Any other Android app added later will hit the same crash.

Outputs in `halium/out/target/product/gtowifi/` (sha256 in `notes/image-checksums.txt`): `halium-boot.img` 17.1 MB, `system.img` 271.6 MB (sparse; fs size 4,076,863,488 = partition size), `vendor.img` 476.6 MB (sparse; fs size 796,917,760 = partition size, ~320 MB spare). `halium/out` is 42 GB. **None of these has been flashed or booted.** The tablet's current vendor partition is LineageOS 22.2 and must be replaced by this `vendor.img` for Halium 9 to work.

## Flashing log (2026-11-06)
- Pushed with halium-install (`-p ut16.04 -s`): `/data/rootfs.img` (3 GiB) and `/data/android-rootfs.img` (453 MB). Rootfs is the old Xenial (16.04) `ubuntu-touch-android9-arm64.tar.gz`, CI build #956, sha256 in `downloads/rootfs/SHA256SUM.txt`.
- Lineage recovery rejects host adb keys (shows `unauthorized`), so root-adb/dd is not possible there; only **Apply update > Apply from ADB** (sideload) works. We flash by sideloading a zip built by `flash/build-flash-zip.py` (stored, 4096-aligned payload; update-binary dd's it out of the zip and verifies by read-back). Recovery asks to install an unsigned zip: answer yes.
- First flash (`flash/halium-flash.zip`: vendor.raw.img + boot.img): "Install completed with status 0", i.e. vendor and boot both verified. 
- First boot attempt: Samsung bootloader printed **"secure check fail boot.img"**. Cause: LineageOS's `mkbootimg.mk` for gtowifi appends `SEANDROIDENFORCE` + a 512-byte fake `SignerVer02` struct to the boot image; the Halium boot image lacked it. Fix: `flash/samsung-sign-boot.py` appends them (528 bytes + zero pad to 4096) -> `flash/boot-samsung.img`; flashed via `flash/halium-boot-fix.zip`. TODO: make the build do this automatically (the Lineage tree also adds an AVB hash footer; not added here because the tablet's vbmeta has verification disabled).
- Do NOT use "Factory reset / Format data" in recovery: it deletes the two images in /data.
- Adding the trailer alone, then trailer + AVB footer (`flash/boot-avb.img`), still gave "secure check fail".
- **Fix that got past the Samsung check (2026-11-06 16:30):** compared field-by-field with LineageOS's official `boot.img` (20261104, `downloads/lineage-ref/`, script `notes/compare-bootimg.py`). Made `flash/boot-lineagelike.img`: header `os_version` set to Lineage's (Android 15.0.0, SPL 2026-10) instead of 9.0.0 / 2022-01, `second_addr` 0, trailer with NO extra zero padding (AVB original_size = image + 528 exactly), unsigned AVB hash footer (+ `com.android.build.boot.os_version=15` prop) written by `flash/avb_footer.py` (verified byte-identical to avbtool output). Result: bootloader accepted it and shows the Samsung logo. Most likely cause: SPL rollback check (2022-01 < device's 2026-10). TODO: set PLATFORM/boot SPL properly in the build instead of patching.

## Bring-up log, evening 2026-11-06 (Ubuntu Touch boots; display not yet)
Boot chain now works: bootloader -> our kernel -> Halium initrd -> Ubuntu Touch (Xenial rootfs) in ~13 s.
Current boot image on the tablet: `flash/boot-halium-vt.img` built from the latest kernel (binder fix + VT) +
`flash/ramdisk-halium-kmsgconsole2.cpio.gz` + cmdline `... datapart=/dev/mmcblk0p69`, Lineage os_version, Samsung trailer, AVB footer
(build with `flash/mkboot_v1.py` + `flash/avb_footer.py`; write via `sudo dd of=/dev/mmcblk0p58` over SSH, verify sha256).
Fixes in order (all done):
1. initrd telnet/USB: removed `rndis_bam` from `scripts/panic/telnet` (Qualcomm IPA RNDIS not supported on msm8937).
2. `datapart=/dev/mmcblk0p69` on cmdline (initrd could not find userdata).
3. initrd `run-init`: both calls use `-c /dev/kmsg` (no console device before VT was enabled).
4. Ubuntu Touch `/usr/bin/usb-tethering` patched to drop `rndis_bam` (backup `.orig` in the image).
5. udev rules `notes/udev/70-gtowifi.rules` installed in rootfs at `/etc/udev/rules.d/70-gtowifi.rules` (host /dev perms, e.g. hwbinder 0666).
6. NetworkManager: `/etc/NetworkManager/conf.d/99-halium-usb-unmanaged.conf` (rndis0/usb0 unmanaged).
7. `/etc/sudoers.d/90-phablet-nopasswd` (user agreed; delete to undo).
8. KERNEL: `drivers/android/binder.c` - deliver transactions without secctx when LSM returns -EOPNOTSUPP (AppArmor). Patch: `notes/0001-binder-allow-transactions-without-secctx.patch`. This made all HIDL services register (107).
9. KERNEL: CONFIG_VT, VT_CONSOLE, CONSOLE_TRANSLATIONS on; VT_HW_CONSOLE_BINDING, FRAMEBUFFER_CONSOLE off (Mir needs a VT).
10. GPU firmware: replaced a530_pfp.fw + a506_zap.{b01,elf,mdt} on vendor with LineageOS 22.2 versions (TheMuppets/proprietary_vendor_samsung_gtowifi); originals in `/vendor/firmware/orig-a9/`. Fixed "GPU PAGE FAULT / CP initialization failed to idle".
11. Vendor partition: added `android.hardware.graphics.composer@2.1-service` + `allocator@2.0-service` (+ .rc) built via `./halium-build.sh mods ...`; added to device.mk too.
12. Vendor partition: `/vendor/ueventd.rc` = Lineage `ueventd.qcom.rc` (the Android container has its OWN tmpfs /dev; mdss_rotator/kgsl/ion were root 0600 there -> composer failed "open /dev/mdss_rotator Permission denied"). Also added to device.mk.

**MILESTONE 2026-11-06 ~18:03: Ubuntu Touch boot logo, then the Unity 8 setup wizard, shown on the tablet's screen.**
13. Device VINTF manifest: `halium/device/samsung/gtowifi/manifest.xml` (12 HALs incl. composer 2.1, allocator 2.0, health, power,
    light, vibrator, wifi 1.2, bluetooth, gnss, configstore, drm) installed at `/vendor/etc/vintf/manifest.xml`; BoardConfig now sets
    DEVICE_MANIFEST_FILE. Without it the full-Treble libhidl refused the IComposer lookup ("failed to get hwcomposer service").
Still open: USB network/SSH unreliable (dropped again on the milestone boot); touch, Wi-Fi, audio, sensors, camera, battery untested.

Open problems (as of 17:58):
- Display: Mir (unity-system-compositor) "failed to get hwcomposer service"; composer service failed on mdss_rotator perms -> fix 12 just applied, result not yet checked. Logo stayed up longer on this boot.
- Vendor partition has NO device manifest (`/vendor/manifest.xml` missing; DEVICE_MANIFEST_FILE not set in BoardConfig). May be needed for clients to find hwbinder services (composer).
- USB network sometimes dies ~10 s into boot: host DHCP gets no reply; Android container init (pid ~1068) does an ioctl on rndis0 around then. Some boots SSH works for minutes, some not.
- pstore console log stops recording early on this kernel; use Ubuntu Touch syslog on userdata (`system-data/var/log/syslog`, `.../lightdm/unity-system-compositor.log`) via recovery instead.
Access: SSH `ssh -i notes/ssh/tablet_key -o UserKnownHostsFile=notes/ssh/known_hosts phablet@10.15.19.82` (passwordless sudo). Recovery: Power+VolDown 10 s, then VolUp+Power; user enables ADB in Lineage recovery -> adb root shell. Reboot from recovery with `adb shell setprop sys.powerctl reboot` (adb reboot / fastboot reboot go back to recovery: unknown reboot reason).

## Wi-Fi + audio bring-up, 2026-11-06 ~18:15 (both WORKING)
Result: `wlan0` up, NetworkManager scans networks (setup wizard should list them); speaker sound confirmed by ear (paplay).
Root causes and fixes (applied on the tablet; also folded into the device tree / `overlay/`, NOT yet rebuilt):
14. Nothing started the DSPs (Lineage does it in init.qcom.rc + wcnss_service, which Halium does not run).
    New upstart job `overlay/rootfs/etc/init/gtowifi-hw.conf` -> `/etc/init/` on the rootfs, `start on android`:
    sets `firmware_class.path=/vendor/firmware_mnt/image`, `echo 1 > /sys/kernel/boot_adsp/boot` (ADSP),
    opens `/dev/wcnss_wlan` (boots WCNSS firmware), `echo sta > /sys/module/wlan/parameters/fwpath` (built-in prima -> wlan0).
    Log: `/var/log/gtowifi-hw.log`. The WCNSS driver CANNOT retry after a failed firmware load (`penv = NULL`) until reboot,
    so the job waits for `wcnss.mdt` and never triggers early.
15. Firmware partitions never mounted: vendor.img had no `/vendor/firmware_mnt` / `/vendor/firmware-modem` folders, so
    mount-android.sh's mounts of apnhlos/modem failed silently -> "Failed to locate wcnss.mdt / adsp.mdt". Created on the
    tablet's vendor partition; device tree now has `Android.mk` creating them (+ `/vendor/dsp`), as Lineage does.
16. Wi-Fi config: `/vendor/etc/wifi/WCNSS_qcom_cfg.ini` (Lineage 19.1) and links in `/vendor/firmware/wlan/prima/`
    (cfg.ini -> /vendor/etc/wifi, `WCNSS_qcom_wlan_nv.bin` + `WCNSS_wlan_dictionary.dat` -> /mnt/vendor/persist, the per-device
    calibration on the persist partition). Device tree: `configs/wifi/`, device.mk, Android.mk.
17. Audio configs missing from vendor (audio_policy_configuration.xml, mixer_paths*, audio_platform_info*...): 25 files copied
    from the Lineage 19.1 tree (3 existing vendor-blob files left alone). Device tree: `configs/audio/`, device.mk.
18. Audio HAL wanted `/vendor/etc/mixer_paths_sdm439_pm8953.xml` (card `sdm439-snd-card-mtp`) -> symlink to `mixer_paths_mtp.xml`
    (superset of mixer_paths.xml incl. speaker amp aw87319 / headset controls, all present on the card). Device tree: Android.mk.
Found on the way:
- Random reboots ~40 s into boot were Ubuntu Touch's `watchdog`: "'bluebinder' hit respawn limit - rebooting" (Bluetooth HAL
  bridge failing; Bluetooth runs on WCNSS too). Not re-checked since WCNSS works. Also `audiosystem-passthrough` hit its respawn limit.
- The rndis0 "unsupported cmd[35585/35591]" kernel lines are just SIOCGIWNAME/SIOCGIWMODE wireless-extension probes: harmless.
- Debug job `overlay/rootfs/etc/init/rndis-keepalive.conf` installed (re-adds 10.15.19.82 to rndis0, logs to
  `/var/log/rndis-keepalive.log` + `/var/log/rndis-monitor.log`). DELETE before release.
- Rootfs edits over SSH: `sudo mount -o remount,rw /` ... `sudo mount -o remount,ro /`; vendor: same with `/android/vendor`.

## Bluetooth bring-up, 2026-11-06 ~18:20 -> WORKING ~18:35
Result: new kernel (BT options below) flashed as `flash/boot-halium-bt.img` (sha256 fe4b655b...; built by
`flash/make-halium-boot.py boot-halium-vt.img <halium-boot.img> out.img`, which first proves the recipe by rebuilding the
template byte-identical; written with dd over SSH, read-back verified). bluebinder: "Successfully initialized vhci bluetooth",
hci0 UP RUNNING with the derived address; btmgmt find sees LE + classic devices. (`hcitool lescan` gives "Set scan
parameters failed: I/O error" on the virtual controller; BlueZ discovery, which Settings uses, works.)
22. `audiosystem-passthrough` (session job, QTI mode) needs the modem call-audio HAL vendor.qti.qcril.am IQcRilAudio, which a
    Wi-Fi-only tablet never has -> respawn limit every boot -> session-watchdog reboots (max once/hour). Disabled with
    `overlay/rootfs/usr/share/upstart/sessions/audiosystem-passthrough.override` ("manual"), installed on the tablet.
    Verified: 0 respawn-limit hits after reboot; audio sinks unaffected.
Details:
bluebinder (Ubuntu Touch's bridge to the Android BT HAL) failed every start -> watchdog reboots. Causes:
19. Kernel: Lineage defconfig has `# CONFIG_BT_BREDR is not set` and no VHCI/RFCOMM/BNEP/HIDP/LE; bluebinder needs
    `/dev/vhci` ("Failed to open /dev/vhci"). Added BT_BREDR, BT_LE, BT_RFCOMM(+TTY), BT_BNEP(+filters), BT_HIDP,
    BT_HCIVHCI to `halium_gtowifi_defconfig` (+ notes/halium-gtowifi.config). NEEDS kernel rebuild + boot reflash.
20. No BT address: "Failed to get bluetooth address!". The QTI BT HAL (pronto/SMD transport, default when
    vendor.qcom.bluetooth.soc unset) and bluebinder_post.sh read `persist.vendor.service.bdroid.bdaddr`. Tablet has no
    stored BT address; gtowifi-hw job now sets it to the efs Wi-Fi MAC with last byte - 1. Verified set.
21. Wi-Fi used Qualcomm's placeholder MAC 00:0a:f5:..; this prima has no wlan_mac.bin loader, it takes the MAC from the
    WCNSS core (`wcnss_mac_addr` sysfs, written by wcnss_service on Lineage). gtowifi-hw job writes the efs MAC
    (`/mnt/vendor/efs/wifi/.mac.info`) there before starting the driver. Verified wlan0 now has the Samsung MAC.

## Hardware tests, 2026-11-06 ~18:37
- Battery: WORKS. /sys/class/power_supply/battery (capacity, status, health, voltage, current, temp); UPower DisplayDevice
  shows the right % and time-to-full. Cosmetic: UPower counts `battery` and `bms` both, so its energy (Wh) totals are
  doubled; `main` reports 0 Wh. Percentage unaffected. Possible later fix: hide bms/main from UPower.
- Buttons: WORK (user confirmed). Power + Volume Down = qpnp_pon (event0), Volume Up = soc:gpio_keys (event5); power
  blanks/unblanks the screen.
- Sensors: NOT working yet. sensorfwd runs (hybris adaptors) but no android.hardware.sensors@1.0::ISensors service.
  Missing vs Lineage: USE_SENSOR_MULTI_HAL (AOSP multi-HAL sensors.gtowifi reading /vendor/etc/sensors/hals.conf ->
  sensors.ssc.so + sensors.rp.so), android.hardware.sensors@1.0-service, the sensors.qti SSC daemon (Lineage starts it from
  init.target.rc / init.qcom.sensors.sh), and the VINTF entry. 23. All added to the device tree (BoardConfig, device.mk,
  manifest.xml, configs/sensors/hals.conf, rootdir/etc/init/init.gtowifi.sensors.rc). Built with
  `./halium-build.sh mods sensors.gtowifi android.hardware.sensors@1.0-service`, installed on vendor (checksums verified;
  old VINTF manifest kept as /vendor/etc/vintf/manifest.xml.pre-sensors).
- 24. sensors.qti then failed: "msm_ipc_router_bind: sensors.qti Do not have permissions" (kernel IPC router needs
  CAP_NET_BIND_SERVICE or CAP_NET_RAW to register a QMI service) -> "Timeout waiting for SMGR service". Fixed with
  `capabilities NET_BIND_SERVICE` on the service in init.gtowifi.sensors.rc; also added Lineage's irsc_util service +
  `/vendor/etc/sec_config` (QMI access rules; configs/sec_config, device.mk).
- Sensors / auto-rotation: WORK (user confirmed rotation, 2026-11-06 ~18:45).
- Camera: NOT working yet. Camera app opens but shows "doesn't have permission" (its generic message for any camera
  failure). Halium camera_service + media.camera run, camera.msm8937.so (32-bit, daemonless mct_shimlayer stack: no
  mm-qcamera-daemon needed; Lineage's qcamerasvr rc entry is stale) is on vendor, but Android 9's camera service only
  reaches HALs through `android.hardware.camera.provider@2.4::ICameraProvider/legacy/0`, which was never built.
  25. Added camera.provider@2.4-impl + @2.4-service (32-bit) to device.mk and legacy/0 to manifest.xml. Built and
  installed (14 files, checksums verified). Provider then failed: "dlopen failed: library android.hidl.base@1.0.so not
  found" (camera.msm8937.so blob links it separately; Android 9 builds it into libhidltransport and only installs the .so
  when asked). Full dependency walk of the camera HAL (24 libs) found nothing else missing.
  26. `make android.hidl.base@1.0` fails ("unknown target"): in this Android 9 tree that interface has no library of its
  own (its code is inside libhidlbase.so). Fix: symlink `/vendor/lib/android.hidl.base@1.0.so -> /system/lib/libhidlbase.so`
  (made on the tablet from recovery; device tree: Android.mk HIDL_BASE_SYMLINK; removed the bad PRODUCT_PACKAGES line).
  Result (~22:55): camera.provider@2.4 legacy/0 running, CameraService reports cameraId 0 and 1. Camera app test pending.
  Side notes from that boot (not fixed): audio_hw can't dlopen soundfx/libqcomvisualizer.so, libqcompostprocbundle.so and
  libadm.so (audio effects only); StagefrightPluginLoader can't load libstagefright_ccodec.so (Codec2, unused on Android 9).
  Lineage also sets TARGET_USES_YCRCB_CAMERA_PREVIEW := true (display HAL); not added yet, try if preview is wrong.

## Security / provenance (not fully verified)
- Sources: Halium and LineageOS repos on GitHub, Google's `repo` launcher, and the third-party `AndroidBlobs/vendor_samsung_gtowifi` binary blobs (~2,600 .so files, 8 APKs, 26 jars, 27 kernel modules that are not covered by any signature I checked).
- Checked: manifest remotes (github, gitlab, android.googlesource.com; the `private` ssh remote is unused), git origins of the manual clones, no network-fetching strings in the device files I wrote.
- Not checked: no checksum of the `repo` launcher; a ClamAV scan of the vendor and kernel trees was started and then stopped at your request (ClamAV definitions were from 2026-10-23); the blobs were not compared against Samsung's own firmware package.
- Side effect: `gpg` created `~/.gnupg` when I tried to verify the `repo` tag signature (the signing key was not in the keyring, so that check did not complete).

## Next
1. Install Docker, then `./build-env.sh image`.
2. Write `halium/device/samsung/gtowifi` (BoardConfig, device makefile, `halium_gtowifi.mk`), using the Lineage 19.1 tree and the stock Android 9 fstab as reference.
3. Merge `notes/halium-gtowifi.config` into the defconfig, rebuild the check, build the kernel and `halium-boot`.
4. Boot test over USB (RNDIS/telnet). Unlocked bootloader means flash via Odin/Heimdall or fastboot-style recovery as appropriate; not yet planned in detail.
