#!/bin/bash

# Create a new log file or clear existing one
> kernel_build.log

{
    echo "[i] Build started at $(date -u +'%Y-%m-%d %H:%M:%S') UTC"

#Some kernels need cross compilers from gcc
	export CROSS_COMPILE=aarch64-linux-gnu-
	export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

    echo "[+] Cleaning build directory..."
    make clean mrproper O=out

    echo "[+] Generating defconfig..."
    make O=out ARCH=arm64 LLVM=1 vendor/spes-perf_defconfig

    echo "[+] Building the kernel..."
    make -j$(nproc) O=out ARCH=arm64 LLVM=1 Image.gz dtbo.img

    echo "[i] Build ended at $(date -u +'%Y-%m-%d %H:%M:%S') UTC"

} 2>&1 | tee -a kernel_build.log
