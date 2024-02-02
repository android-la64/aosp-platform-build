# Copyright (C) 2018 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# loongarch64 emulator specific definitions
TARGET_ARCH := loongarch64
TARGET_ARCH_VARIANT := loongarch64
TARGET_CPU_VARIANT := generic
TARGET_CPU_ABI := loongarch64

#TARGET_2ND_ARCH := arm
#TARGET_2ND_CPU_ABI := armeabi-v7a
#TARGET_2ND_CPU_ABI2 := armeabi


include build/make/target/board/BoardConfigGsiCommon.mk
#include build/make/target/board/BoardConfigGkiCommon.mk

TARGET_NO_KERNEL := false  # Output ramdisk.img if true else boot.img

BOARD_AVB_ENABLE := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 0x2000000

BOARD_USES_METADATA_PARTITION := true

BOARD_USERDATAIMAGE_PARTITION_SIZE := 576716800

# AB, no retrofit
BOARD_SUPER_PARTITION_SIZE := 4294967296 # 4GB
BOARD_SUPER_PARTITION_GROUPS := loongarch64_dynamic_partitions
BOARD_LOONGARCH64_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor
BOARD_LOONGARCH64_DYNAMIC_PARTITIONS_SIZE := 2143289344 # 4GB/2 - 4M
BOARD_SUPER_PARTITION_METADATA_DEVICE := super
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_IMAGE_IN_UPDATE_PACKAGE := true

# system_ext.img
#BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
#TARGET_COPY_OUT_SYSTEM_EXT := system_ext

#vendor_ramdisk.img
BOARD_BUILD_VENDOR_RAMDISK_IMAGE := true
#PRODUCT_PACKAGES += \
#    linker.vendor_ramdisk \
#    e2fsck.vendor_ramdisk \

# FIXME: Remove this once we generate the vbmeta digest correctly
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2

# Enable chained vbmeta for system image mixing. output vbmeta_system.img
# Note: must be disable BOARD_AVB_SYSTEM* in BoardConfigGsiCommon.mk
#BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM := system
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1


ifeq ($(TARGET_PREBUILT_KERNEL),)
    LOCAL_KERNEL := device/loongson/loongson-kernel/vmlinuz.efi
else
    LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES += \
    $(LOCAL_KERNEL):kernel


BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true

BOARD_BOOTCONFIG += androidboot.console=ttyS0
BOARD_BOOTCONFIG += androidboot.bootreason=cold,powerkey
BOARD_BOOTCONFIG += androidboot.usb_mode=3
BOARD_BOOTCONFIG += androidboot.usb_speed=5
#BOARD_BOOTCONFIG += androidboot.boot_devices=soc/ffe7080000.sdhci
BOARD_BOOTCONFIG += androidboot.slot_suffix=_a

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
BOARD_BOOTCONFIG += androidboot.selinux=permissive
endif

BOARD_KERNEL_CMDLINE += bootconfig
# Include *.dtb to vendor_boot.img and use Android Boot Image v4
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

# vendor_boot.img
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 0x02000000
