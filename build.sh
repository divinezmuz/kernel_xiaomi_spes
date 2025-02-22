#!/bin/bash

# Current time (UTC)
BUILD_START_TIME="$(date -u +'%Y-%m-%d %H:%M:%S')"

# Basic setup
export ARCH=arm64
export SUBARCH=arm64

# Toolchain paths
export CLANG_PATH=~/spes/clang/bin
export PATH=${CLANG_PATH}:${PATH}
export CROSS_COMPILE=~/spes/gcc-arm64/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=~/spes/gcc-arm32/bin/arm-eabi-
export CLANG_TRIPLE=aarch64-linux-gnu-

# Build flags
export KBUILD_BUILD_USER="${CURRENT_USER}"
export KBUILD_BUILD_HOST="github"
export KBUILD_COMPILER_STRING="$(${CLANG_PATH}/clang --version | head -n 1 2>&1)"
export LD=ld.lld

# Start build process
{
    echo "[i] Build started at ${BUILD_START_TIME} UTC"
    echo "[i] Compiler: ${KBUILD_COMPILER_STRING}"

    # Check toolchain
    if [[ ! -f "${CLANG_PATH}/clang" || ! -f "$(dirname ${CROSS_COMPILE})/$(basename ${CROSS_COMPILE})gcc" ]]; then
        echo "[✗] Toolchain missing!"
        exit 1
    fi

    echo "[+] Cleaning build directory..."
    make clean mrproper O=out &>/dev/null

    echo "[+] Generating defconfig..."
    make O=out \
        CC=clang \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        KCFLAGS="-Wno-address-of-packed-member -Wno-int-in-bool-context" \
        vendor/spes-perf_defconfig

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "[✗] Failed to generate defconfig!"
        exit 1
    fi

    echo "[+] Building kernel..."
    make O=out \
        CC=clang \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        KCFLAGS="-Wno-address-of-packed-member -Wno-int-in-bool-context" \
        -j$(nproc)

    BUILD_RESULT=${PIPESTATUS[0]}

    # Check for either Image.gz or Image.gz-dtb since different configs might generate different names
    if [ $BUILD_RESULT -eq 0 ] && { [ -f out/arch/arm64/boot/Image.gz ] || [ -f out/arch/arm64/boot/Image.gz-dtb ]; }; then
        echo "[✓] Build completed successfully!"
        if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
            echo "[i] Kernel: out/arch/arm64/boot/Image.gz-dtb"
        else
            echo "[i] Kernel: out/arch/arm64/boot/Image.gz"
        fi
        BUILD_STATUS="success"
    else
        echo "[✗] Build failed with code: $BUILD_RESULT"
        BUILD_STATUS="failed"
    fi

    echo "[i] Build ended at $(date -u +'%Y-%m-%d %H:%M:%S') UTC"

} 2>&1 | tee kernel_build.log

# Return the actual build result
exit ${BUILD_RESULT}
