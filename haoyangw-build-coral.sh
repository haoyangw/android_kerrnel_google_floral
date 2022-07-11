#!/bin/bash

# Taken from https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-coral-4.14-android12-qpr3
KERNEL_DIR=$(pwd .)
# Taken from sub-directory 'clang-r416183b/' of https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master 
PREBUILT_CLANG=/home/exp2/bin/prebuilts-clang-host-linux-x86/clang-r416183b
LD_LIBRARY_PATH="${PREBUILT_CLANG}/lib64:${LD_LIBRARY_PATH}"
# Taken from https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+/refs/heads/android-msm-coral-4.14-android12-qpr3
PREBUILT_GCC_AARCH64=/home/exp2/bin/prebuilts-gcc-linux-x86/aarch64-linux-android-4.9
# Taken from https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+/refs/heads/android-msm-coral-4.14-android12-qpr3
PREBUILT_GCC_ARM32=/home/exp2/bin/prebuilts-gcc-linux-x86/arm-linux-androideabi-4.9
# Taken from https://android.googlesource.com/platform/prebuilts/misc/+/refs/heads/android-msm-coral-4.14-android12-qpr3
PREBUILT_MISC=/home/exp2/bin/prebuilts-misc
LZ4_PREBUILTS_BIN="${PREBUILT_MISC}/linux-x86/lz4"
DTC_PREBUILTS_BIN="${PREBUILT_MISC}/linux-x86/dtc"
LIBUFDT_PREBUILTS_BIN="${PREBUILT_MISC}/linux-x86/libufdt"
DTC_EXT="${DTC_PREBUILTS_BIN}/dtc"
DTC_OVERLAY_TEST_EXT="${LIBUFDT_PREBUILTS_BIN}/ufdt_apply_overlay"
PATH="${PREBUILT_CLANG}/bin:${PREBUILT_GCC_AARCH64}/bin:${PREBUILT_GCC_ARM32}/bin:${LZ4_PREBUILTS_BIN}:${DTC_PREBUILTS_BIN}:${LIBUFDT_PREBUILTS_BIN}:${PATH}"

# Toolchain configs
DEFCONFIG=floral_exfat_perf_defconfig
ARCH=arm64
CC=clang
CLANG_TRIPLE=aarch64-linux-gnu-
CROSS_COMPILE=aarch64-linux-android-
CROSS_COMPILE_ARM32=arm-linux-androideabi-
LD=ld.lld

echo ""

if [ -d "${KERNEL_DIR}/out" ]; then
    read -p "Output directory exists. Would you like to clean it? (Y/n) " choice
    case $choice in
        [Yy]* )
            echo "Cleaning output directory...";
            echo "";
            PATH="$PATH" make O=out ARCH="$ARCH" mrproper;;
        [Nn]* )
            echo "Not cleaning output directory...";
            echo "";;
        * )
            echo "Not cleaning output directory...";
            echo "";;
    esac
fi

if [ ! -f "${KERNEL_DIR}/out/.config" ]; then
    echo ""
    echo "Generating defconfig in output directory..."
    echo ""
    PATH="$PATH" make -j$(nproc) O=out ARCH="$ARCH" "$DEFCONFIG"
fi

echo ""
echo "Compiling kernel..."
echo ""
START_TIME=$(date +%s)

PATH="$PATH" LLVM_PARALLEL_LINK_JOBS=1 make -j$(nproc) O=out ARCH="$ARCH" CC="$CC" CLANG_TRIPLE="$CLANG_TRIPLE" CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" LD="$LD" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" LZ4_PREBUILTS_BIN="$LZ4_PREBUILTS_BIN" DTC_PREBUILTS_BIN="$DTC_PREBUILTS_BIN" LIBUFDT_PREBUILTS_BIN="$LIBUFDT_PREBUILTS_BIN" DTC_EXT="$DTC_EXT" DTC_OVERLAY_TEST_EXT="$DTC_OVERLAY_TEST_EXT"

END_TIME=$(date +%s)

echo ""
echo "Compilation complete"
TOTAL_TIME=$((END_TIME - START_TIME))
DAYS=$((TOTAL_TIME/86400))
TIME_LEFT_1=$((TOTAL_TIME - 86400*DAYS))
HOURS=$((TIME_LEFT_1/3600))
TIME_LEFT_2=$(($TIME_LEFT_1 - 3600*HOURS))
MINS=$((TIME_LEFT_2/60))
SECS=$((TIME_LEFT_2 - 60*MINS))
echo "Took ${DAYS} days ${HOURS} hours ${MINS} mins ${SECS} secs"
echo ""
exit 0

# Output binaries
# -> out/arch/arm64/boot/dtbo.img
# -> out/arch/arm64/boot/Image.lz4-dtb
# -> out/arch/arm64/boot/Image.lz4
# -> out/arch/arm64/boot/dts/google/qcom-base/sdmmagpie.dtb
# -> out/vmlinux
# -> out/System.map
