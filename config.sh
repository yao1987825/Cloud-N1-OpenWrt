#!/bin/bash
cd openwrt

# 禁用 ksmbd 及相关包，避免内核 6.12 与 ksmbd 3.5.4 不兼容
# ksmbd-server 和 autosamba 依赖 kmod-fs-ksmbd，必须一起禁用
rm -rf package/kernel/ksmbd
sed -i 's/CONFIG_PACKAGE_kmod-fs-ksmbd=y/# CONFIG_PACKAGE_kmod-fs-ksmbd is not set/g; s/CONFIG_PACKAGE_ksmbd-server=y/# CONFIG_PACKAGE_ksmbd-server is not set/g; s/CONFIG_PACKAGE_autosamba=y/# CONFIG_PACKAGE_autosamba is not set/g' .config