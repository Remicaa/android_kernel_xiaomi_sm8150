#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${PROJECT_DIR}/out"
AK3_DIR="${PROJECT_DIR}/AnyKernel3"
TOOLCHAIN_DIR="${PROJECT_DIR}/../proton-clang"
ZIP_NAME="${ZIP_NAME:-nabu-kernel-docker-nethunter.zip}"

if [ ! -f "${OUT_DIR}/arch/arm64/boot/Image.gz" ]; then
    echo "ERROR: Kernel image not found in ${OUT_DIR}/arch/arm64/boot/Image.gz"
    exit 1
fi

echo "==> Copying kernel artifacts to AnyKernel3 directory..."
cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${AK3_DIR}/"
cp "${OUT_DIR}/arch/arm64/boot/dtbo.img" "${AK3_DIR}/"

echo "==> Packaging loadable external Wi-Fi kernel modules..."
rm -rf "${AK3_DIR}/modules_ko"
mkdir -p "${AK3_DIR}/modules_ko"
for mod in \
    "${OUT_DIR}/drivers/net/wireless/aic8800/aic_load_fw/aic_load_fw.ko" \
    "${OUT_DIR}/drivers/net/wireless/aic8800/aic8800_fdrv/aic8800_fdrv.ko" \
    "${OUT_DIR}/drivers/net/wireless/realtek/rtl8812au/88XXau.ko"; do
    if [ -f "${mod}" ]; then
        cp "${mod}" "${AK3_DIR}/modules_ko/"
        if [ -x "${TOOLCHAIN_DIR}/bin/llvm-strip" ]; then
            "${TOOLCHAIN_DIR}/bin/llvm-strip" --strip-debug "${AK3_DIR}/modules_ko/$(basename "${mod}")"
        fi
    fi
done
ls -lh "${AK3_DIR}/modules_ko/" 2>/dev/null || true

echo "==> Generating flashable zip (${ZIP_NAME})..."
cd "${AK3_DIR}"
rm -f "${PROJECT_DIR}/${ZIP_NAME}"
zip -r9 "${PROJECT_DIR}/${ZIP_NAME}" * -x .git .gitignore README.md '*placeholder'

echo "============================================="
echo "Flashable zip created successfully!"
ls -lh "${PROJECT_DIR}/${ZIP_NAME}"
echo "============================================="
