#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${PROJECT_DIR}/out"
AK3_DIR="${PROJECT_DIR}/AnyKernel3"
ZIP_NAME="nabu-kernel-fresh-thinlto.zip"

if [ ! -f "${OUT_DIR}/arch/arm64/boot/Image.gz" ]; then
    echo "ERROR: Kernel image not found in ${OUT_DIR}/arch/arm64/boot/Image.gz"
    exit 1
fi

echo "==> Copying kernel artifacts to AnyKernel3 directory..."
cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${AK3_DIR}/"
cp "${OUT_DIR}/arch/arm64/boot/dtbo.img" "${AK3_DIR}/"

echo "==> Generating flashable zip (${ZIP_NAME})..."
cd "${AK3_DIR}"
zip -r9 "${PROJECT_DIR}/${ZIP_NAME}" * -x .git .gitignore README.md *placeholder

echo "============================================="
echo "Flashable zip created successfully!"
ls -lh "${PROJECT_DIR}/${ZIP_NAME}"
echo "============================================="
