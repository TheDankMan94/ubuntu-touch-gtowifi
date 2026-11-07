# Product definition. Named lineage_* because the Halium 9 tree is a LineageOS 16.0 fork,
# so the build is started with: lunch lineage_gtowifi-userdebug
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# Halium parts (added to build/make by hybris-patches).
$(call inherit-product, $(SRC_TARGET_DIR)/product/halium.mk)

$(call inherit-product-if-exists, frameworks/base/data/fonts/fonts.mk)

# Device and proprietary (stock Android 9 vendor) makefiles.
$(call inherit-product, $(LOCAL_PATH)/device.mk)

PRODUCT_BRAND := samsung
PRODUCT_DEVICE := gtowifi
PRODUCT_MANUFACTURER := samsung
PRODUCT_MODEL := SM-T290
PRODUCT_NAME := lineage_gtowifi

TARGET_VENDOR := samsung
TARGET_VENDOR_PRODUCT_NAME := gtowifi

# Stock fingerprint of the Android 9 firmware the vendor files came from.
BUILD_FINGERPRINT := samsung/gtowifixx/gtowifi:9/PPR1.180610.011/T290XXU1ASF7:user/release-keys
PRIVATE_BUILD_DESC := "gtowifixx-user 9 PPR1.180610.011 T290XXU1ASF7 release-keys"
