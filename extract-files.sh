#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=apollo
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

function blob_fixup() {
    case "${1}" in
        vendor/etc/libnfc-nci.conf)
            cat << EOF >> "${2}"
###############################################################################
# Mifare Tag implementation
# 0: General implementation
# 1: Legacy implementation
LEGACY_MIFARE_READER=1
EOF
            ;;
        vendor/etc/camera/camxoverridesettings.txt)
            sed -i "s/0x10098/0/g" "${2}"
            sed -i "s/0x1F/0x0/g" "${2}"
            ;;
        vendor/lib64/camera/components/com.mi.node.watermark.so)
            "${PATCHELF}" --add-needed "libpiex_shim.so" "${2}"
            ;;
        vendor/etc/media_codecs_kona.xml)
            sed -i "/media_codecs_dolby_audio.xml/d" "${2}"
            ;;
        vendor/lib64/libril-qc-hal-qmi.so)
            sed -i 's|ro.product.vendor.device|ro.vendor.radio.midevice|g' "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
            "${SIGSCAN}" -p "9A 0A 00 94" -P "1F 20 03 D5" -f "${2}"
            ;;
        vendor/lib64/hw/camera.qcom.so)
            "${PATCHELF}" --remove-needed "libMegviiFacepp-0.5.2.so" "${2}"
            "${PATCHELF}" --remove-needed "libmegface.so" "${2}"
            "${PATCHELF}" --add-needed "libshim_megvii.so" "${2}"
            ;;
    esac
}

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
