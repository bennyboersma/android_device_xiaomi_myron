#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/xiaomi/myron

# Inherit from SM8850 common tree only when explicitly requested.
# Use `TARGET_SM8850_COMMON_FLAVOR := full` in your build environment to enable.
ifeq ($(TARGET_SM8850_COMMON_FLAVOR),full)
ifneq ($(wildcard device/xiaomi/sm8850-common/common.mk),)
$(call inherit-product, device/xiaomi/sm8850-common/common.mk)
else
$(call inherit-product-if-exists, vendor/xiaomi/sm8850-common/common.mk)
endif
endif
$(call inherit-product, vendor/xiaomi/myron/myron-vendor.mk)
$(call inherit-product-if-exists, vendor/xiaomi/myron/myron-symlinks.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
