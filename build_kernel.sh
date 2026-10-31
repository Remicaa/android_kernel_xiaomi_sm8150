#!/usr/bin/env bash
set -e

KERNEL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="${KERNEL_DIR}/../proton-clang"
OUT_DIR="${KERNEL_DIR}/out"

if [ ! -d "${TOOLCHAIN_DIR}/bin" ]; then
    echo "ERROR: Proton Clang toolchain not found at ${TOOLCHAIN_DIR}"
    exit 1
fi

export PATH="/usr/bin:${TOOLCHAIN_DIR}/bin:${PATH}"

mkdir -p "${OUT_DIR}"

echo "==> [1/4] Merging kernel configs..."
ARCH=arm64 "${KERNEL_DIR}/scripts/kconfig/merge_config.sh" -m -O "${OUT_DIR}" \
    "${KERNEL_DIR}/arch/arm64/configs/vendor/sm8150-perf_defconfig" \
    "${KERNEL_DIR}/arch/arm64/configs/vendor/debugfs.config" \
    "${KERNEL_DIR}/arch/arm64/configs/vendor/xiaomi/sm8150-common.config" \
    "${KERNEL_DIR}/arch/arm64/configs/vendor/xiaomi/nabu.config"

echo "==> [2/4] Generating .config (olddefconfig)..."
make -C "${KERNEL_DIR}" O="${OUT_DIR}" ARCH=arm64 \
    HOSTCC="gcc -B/usr/bin/" HOSTLD=/usr/bin/ld \
    CC="${TOOLCHAIN_DIR}/bin/clang" \
    LD="${TOOLCHAIN_DIR}/bin/ld.lld" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE="${TOOLCHAIN_DIR}/bin/aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="${TOOLCHAIN_DIR}/bin/arm-linux-gnueabi-" \
    olddefconfig

echo "==> [3/4] Verifying LTO configuration..."
grep -E "CONFIG_LTO|CONFIG_THINLTO" "${OUT_DIR}/.config" || true

START_TIME=$(date +%s)
echo "==> [4/4] Compiling kernel (Image.gz dtbo.img dtbs) with $(nproc) threads..."
make -C "${KERNEL_DIR}" O="${OUT_DIR}" -j"$(nproc)" ARCH=arm64 \
    HOSTCC="gcc -B/usr/bin/" HOSTLD=/usr/bin/ld \
    CC="${TOOLCHAIN_DIR}/bin/clang" \
    LD="${TOOLCHAIN_DIR}/bin/ld.lld" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE="${TOOLCHAIN_DIR}/bin/aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="${TOOLCHAIN_DIR}/bin/arm-linux-gnueabi-" \
    Image.gz dtbo.img dtbs

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "============================================="
echo "Build completed in $((ELAPSED / 60))m $((ELAPSED % 60))s"
echo "Artifacts:"
ls -lh "${OUT_DIR}/arch/arm64/boot/Image.gz" "${OUT_DIR}/arch/arm64/boot/dtbo.img" 2>/dev/null || true
echo "============================================="

echo "==> Packaging into AnyKernel3 flashable zip..."
"${KERNEL_DIR}/package_kernel.sh"

