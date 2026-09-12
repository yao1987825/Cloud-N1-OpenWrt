#!/bin/bash
cd openwrt

# 禁用 ksmbd 及相关包，避免内核 6.12 与 ksmbd 3.5.4 不兼容
# ksmbd-server 和 autosamba 依赖 kmod-fs-ksmbd，必须一起禁用
rm -rf package/kernel/ksmbd
sed -i 's/CONFIG_PACKAGE_kmod-fs-ksmbd=y/# CONFIG_PACKAGE_kmod-fs-ksmbd is not set/g; s/CONFIG_PACKAGE_ksmbd-server=y/# CONFIG_PACKAGE_ksmbd-server is not set/g; s/CONFIG_PACKAGE_autosamba=y/# CONFIG_PACKAGE_autosamba is not set/g' .config

# 禁用 armsr 的 combined-efi.img.gz 输出
# N1 不使用 EFI 启动，但 armsr target 默认会编译 grub2-efi-arm 并生成 combined-efi 镜像
# 这会触发 "root-armsr/boot/. not found" → mkfs.fat file already exists 错误
# 通过 patch image/Makefile 移除 combined-efi 相关条目，保留 rootfs.img.gz 与 rootfs.tar.gz
armsr_image_mk="target/linux/armsr/image/Makefile"
if [[ -f "$armsr_image_mk" ]]; then
  sed -i '/IMAGE\/combined-efi\.img/d; /IMAGE\/combined-efi\.vmdk/d; /IMAGES-y += combined-efi\.img\.gz/d; /IMAGES-y += combined-efi\.img/d; /IMAGES-y += combined-efi\.vmdk/d' "$armsr_image_mk"
fi