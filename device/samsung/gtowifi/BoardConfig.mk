# BoardConfig for Samsung Galaxy Tab A 8.0 (2019) Wi-Fi, SM-T290 (gtowifi), Halium 9.
# Values come from the LineageOS gtowifi tree (partition sizes, offsets, cmdline) and the
# Halium X00TD example (Halium-specific cmdline and Treble settings).
# UNTESTED: not yet built or booted.

DEVICE_PATH := device/samsung/gtowifi

BOARD_VENDOR := samsung

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := SRPSB22C003
TARGET_NO_BOOTLOADER := true

# Platform
TARGET_BOARD_PLATFORM := msm8937
TARGET_BOARD_PLATFORM_GPU := qcom-adreno504

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

TARGET_USES_64_BIT_BINDER := true

# Assert
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_OTA_ASSERT_DEVICE := gtowifi

# Kernel
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3
BOARD_KERNEL_CMDLINE += lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci
BOARD_KERNEL_CMDLINE += androidboot.usbconfigfs=true loop.max_part=7 androidboot.fstab_suffix=qcom
BOARD_KERNEL_CMDLINE += androidboot.boot_devices=soc/7824900.sdhci
# Halium: AppArmor instead of SELinux, no audit noise, console on the tablet screen
BOARD_KERNEL_CMDLINE += apparmor=1 security=apparmor audit=0 selinux=0 console=tty0

BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x02000000
BOARD_KERNEL_TAGS_OFFSET := 0x01e00000
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMG_HEADER_VERSION := 1
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --board $(TARGET_BOOTLOADER_BOARD_NAME)
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_SOURCE := kernel/samsung/sdm429
TARGET_KERNEL_CONFIG := lineageos_gtowifi_defconfig
# Halium requirements merged on top (see notes/halium-gtowifi.config)
TARGET_KERNEL_ADDITIONAL_CONFIG := halium_gtowifi_defconfig
TARGET_KERNEL_VERSION := 4.9
TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-
# The LineageOS 4.9 kernel rejects the tree's GCC 4.9 on arm64 (needs GCC >= 5.1 or clang), so build with
# the tree's clang 6.0.2 (the clang Android 9 4.9 kernels were officially built with).
TARGET_KERNEL_CLANG_COMPILE := true
# (clang path is left to vendor/lineage/build/tasks/kernel.mk; it defaults to prebuilts clang-4691093)
# The kernel's arch/arm64/Makefile passes `dtc -@` (overlay symbols) but its in-tree dtc is too old for it,
# so use the Android tree's prebuilt dtc (DTC 1.4.2-Android) through the kernel's DTC_EXT hook.
TARGET_KERNEL_ADDITIONAL_FLAGS := DTC_EXT=$(shell pwd)/prebuilts/misc/linux-x86/dtc/dtc

# Treble
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml
BOARD_VNDK_VERSION := current
PRODUCT_USE_VNDK_OVERRIDE := false
PRODUCT_SHIPPING_API_LEVEL := 28
BOARD_VNDK_RUNTIME_DISABLE := true
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Camera (32-bit only HAL)
TARGET_USES_QTI_CAMERA_DEVICE := true
BOARD_QTI_CAMERA_32BIT_ONLY := true

# Display / graphics
TARGET_USES_ION := true
TARGET_USES_HWC2 := true
# Without this the Qualcomm display HAL (hardware/qcom/display-caf/msm8996) links the legacy
# libmemalloc, which is not built for this variant ("libmemalloc ... export_includes missing").
TARGET_USES_GRALLOC1 := true
TARGET_USES_OVERLAY := true
MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024
TARGET_SCREEN_DENSITY := 213
TARGET_SCREEN_WIDTH := 800
TARGET_SCREEN_HEIGHT := 1280
# Halium never shows Android's boot animation; a placeholder avoids Lineage's ImageMagick-based generator.
TARGET_BOOTANIMATION := $(DEVICE_PATH)/bootanimation-placeholder.zip

# Sensors: build AOSP's multi-HAL (sensors.$(TARGET_DEVICE)) that reads /vendor/etc/sensors/hals.conf
USE_SENSOR_MULTI_HAL := true

# Audio
BOARD_USES_ALSA_AUDIO := true
USE_CUSTOM_AUDIO_POLICY := 1

# Bluetooth
BOARD_HAVE_BLUETOOTH_QCOM := true

# QCOM
BOARD_USES_QCOM_HARDWARE := true

# Partitions (sizes from the LineageOS tree; system-as-root as on the stock firmware)
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x04000000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x04000000
BOARD_CACHEIMAGE_PARTITION_SIZE := 317718528
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4076863488
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_SIZE := 796917760
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_COPY_OUT_VENDOR := vendor
PRODUCT_VENDOR_MOVE_ENABLED := true

BOARD_ROOT_EXTRA_FOLDERS := efs
BOARD_ROOT_EXTRA_SYMLINKS := \
    /mnt/vendor/persist:/persist \
    /vendor/dsp:/dsp \
    /vendor/firmware_mnt:/firmware

# Recovery: Halium does not build one
TARGET_NO_RECOVERY := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom

# SELinux: the kernel runs with selinux=0; policy is only built to satisfy the Android build.
include device/qcom/sepolicy/sepolicy.mk

# Security patch level of the stock firmware (Sept 2019)
VENDOR_SECURITY_PATCH := 2019-09-01

# Wifi
BOARD_HAS_QCOM_WLAN := true
BOARD_WLAN_DEVICE := qcwcn
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_AP := "ap"
WPA_SUPPLICANT_VERSION := VER_0_8_X

# Proprietary board config from the vendor tree
-include vendor/samsung/gtowifi/BoardConfigVendor.mk
