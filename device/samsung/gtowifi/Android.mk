#
# Install-time folders and symlinks for gtowifi (Halium 9).
# Based on the LineageOS 19.1 gtowifi tree's Android.mk (Apache-2.0).
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),gtowifi)

include $(CLEAR_VARS)

# Mount points for the firmware partitions (fstab.qcom). Halium's mount-android.sh mounts
# them onto the read-only vendor partition, so the folders must exist in vendor.img.
# Without /vendor/firmware_mnt the ADSP (audio) and WCNSS (Wi-Fi/Bluetooth) firmware is
# never found: found on the tablet 2026-11-06.
FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware_mnt
$(FIRMWARE_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $@"
	@mkdir -p $@

MODEM_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware-modem
$(MODEM_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $@"
	@mkdir -p $@

DSP_MOUNT_POINT := $(TARGET_OUT_VENDOR)/dsp
$(DSP_MOUNT_POINT): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating $@"
	@mkdir -p $@

ALL_DEFAULT_INSTALLED_MODULES += $(FIRMWARE_MOUNT_POINT) $(MODEM_MOUNT_POINT) $(DSP_MOUNT_POINT)

# Wi-Fi (prima/pronto): the kernel requests wlan/prima/* from /vendor/firmware.
# The NV calibration and dictionary are per-device files on the persist partition.
WCNSS_INI_SYMLINK := $(TARGET_OUT_VENDOR)/firmware/wlan/prima/WCNSS_qcom_cfg.ini
$(WCNSS_INI_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /vendor/etc/wifi/$(notdir $@) $@

WCNSS_BIN_SYMLINK := $(TARGET_OUT_VENDOR)/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
$(WCNSS_BIN_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /mnt/vendor/persist/$(notdir $@) $@

WCNSS_DAT_SYMLINK := $(TARGET_OUT_VENDOR)/firmware/wlan/prima/WCNSS_wlan_dictionary.dat
$(WCNSS_DAT_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /mnt/vendor/persist/$(notdir $@) $@

# Audio: the Android 9 msm8916 audio HAL asks for mixer_paths_sdm439_pm8953.xml on this
# sound card (sdm439-snd-card-mtp). mixer_paths_mtp.xml is the device-tuned file (it has
# the speaker amp and headset controls that exist on the card).
MIXER_SDM439_SYMLINK := $(TARGET_OUT_VENDOR)/etc/mixer_paths_sdm439_pm8953.xml
$(MIXER_SDM439_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf mixer_paths_mtp.xml $@

# The camera HAL blob (camera.msm8937.so) lists android.hidl.base@1.0.so as a separate library. This Android 9 tree
# has no such library (its code is inside libhidlbase), and "make android.hidl.base@1.0" fails with "unknown target".
HIDL_BASE_SYMLINK := $(TARGET_OUT_VENDOR)/lib/android.hidl.base@1.0.so
$(HIDL_BASE_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /system/lib/libhidlbase.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(HIDL_BASE_SYMLINK) $(WCNSS_INI_SYMLINK) $(WCNSS_BIN_SYMLINK) $(WCNSS_DAT_SYMLINK) $(MIXER_SDM439_SYMLINK)

endif
