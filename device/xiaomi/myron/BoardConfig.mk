#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/myron

# Default to full sm8850-common unless explicitly overridden.
TARGET_SM8850_COMMON_FLAVOR ?= full
ifeq ($(TARGET_SM8850_COMMON_FLAVOR),full)
include device/xiaomi/sm8850-common/BoardConfigCommon.mk
endif

# Platform
TARGET_BOARD_PLATFORM := kaanapali
BOARD_USES_ADRENO := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv9-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := myron
TARGET_NO_BOOTLOADER := true

# Kernel
BOARD_BOOTIMG_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01100000
BOARD_DTB_OFFSET := 0x00000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100

BOARD_KERNEL_CMDLINE := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    loop.max_part=16

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_USES_GENERIC_KERNEL_IMAGE := true
# Android 16 GKI Target
TARGET_KERNEL_VERSION := 6.12

MYRON_PREBUILT_IMAGES_DIR := $(DEVICE_PATH)/prebuilt
MYRON_USE_PREBUILT_BOOTIMAGE ?= true
MYRON_USE_PREBUILT_INIT_BOOT_IMAGE ?= true
MYRON_USE_PREBUILT_VENDOR_BOOTIMAGE ?= true
MYRON_USE_PREBUILT_DTBOIMAGE ?= true

ifneq ($(wildcard $(MYRON_PREBUILT_IMAGES_DIR)/boot.img),)
ifeq ($(MYRON_USE_PREBUILT_BOOTIMAGE),true)
BOARD_PREBUILT_BOOTIMAGE := $(MYRON_PREBUILT_IMAGES_DIR)/boot.img
BOARD_PREBUILT_BOOTIMAGE_KEEP_AVB := true
TARGET_NO_KERNEL := true
endif
endif
ifneq ($(wildcard $(MYRON_PREBUILT_IMAGES_DIR)/init_boot.img),)
ifeq ($(MYRON_USE_PREBUILT_INIT_BOOT_IMAGE),true)
BOARD_PREBUILT_INIT_BOOT_IMAGE := $(MYRON_PREBUILT_IMAGES_DIR)/init_boot.img
endif
endif
ifneq ($(wildcard $(MYRON_PREBUILT_IMAGES_DIR)/vendor_boot.img),)
ifeq ($(MYRON_USE_PREBUILT_VENDOR_BOOTIMAGE),true)
BOARD_PREBUILT_VENDOR_BOOTIMAGE := $(MYRON_PREBUILT_IMAGES_DIR)/vendor_boot.img
endif
endif
ifneq ($(wildcard $(MYRON_PREBUILT_IMAGES_DIR)/dtbo.img),)
ifeq ($(MYRON_USE_PREBUILT_DTBOIMAGE),true)
BOARD_PREBUILT_DTBOIMAGE := $(MYRON_PREBUILT_IMAGES_DIR)/dtbo.img
endif
endif

# Partitions
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm

BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 24117248

# Kernel Modules (SM8850)
MYRON_VENDOR_MODULES_DIR := vendor/xiaomi/myron/proprietary/vendor_dlkm/lib/modules
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := \
    adsp_loader_dlkm.ko \
    camera.ko
ifneq ($(wildcard $(MYRON_VENDOR_MODULES_DIR)/modules.load),)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(shell cat $(MYRON_VENDOR_MODULES_DIR)/modules.load)
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(MYRON_VENDOR_MODULES_DIR)/modules.blocklist
endif
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(MYRON_VENDOR_MODULES_DIR)/*.ko) \
    $(wildcard $(DEVICE_PATH)/modules/*.ko)

# Filesystem Types (Phase 2 Verified: EROFS)
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_EROFS_PAGESIZE := 4096
BOARD_EROFS_COMPRESSOR := lz4hc,9

BOARD_USES_ODMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true

# Dynamic Partitions (17GB Super Geometry)
BOARD_SUPER_PARTITION_SIZE := 18253611008
BOARD_SUPER_PARTITION_GROUPS := xiaomi_dynamic_partitions
BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE := 12884901888 # 12GB to allow growth
BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm vendor_dlkm system_dlkm

# A/B System
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vendor \
    vendor_dlkm \
    vendor_boot \
    vbmeta \
    vbmeta_system

# Fingerprint: android.hardware.biometrics.fingerprint (AIDL v4)
# Display: android.hardware.graphics.composer3 (AIDL v4)
# Camera: android.hardware.camera.provider (AIDL v3)
# Audio: android.hardware.audio.core (AIDL v3)

# Encryption
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_VNDK_FOR_PRIVILEGED_COMPONENTS := true

# SM8850 (Snapdragon 8 Elite Gen 5) specific
TARGET_USES_AIDL_COMPOSER := true
TARGET_USES_AIDL_AUDIO_HAL := true
TARGET_USES_AIDL_CAMERA_HAL := true

include vendor/xiaomi/myron/BoardConfigVendor.mk
