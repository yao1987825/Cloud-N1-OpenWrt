# 云编译 N1 OpenWrt 固件

**说明**：
- 本项目使用 Github Actions 下载 [Lean](https://github.com/coolsnowwolf/lede) 的 `Openwrt` 源码仓库，进行云编译。
- 本项目使用定时编译（北京时间每周日下午4点开始运行编译）及触发编译（更新 `README.md`、 `script.sh`、 `config.sh`后可开始编译）两种方式。
- 本项目编译固件适配斐讯 N1 盒子（Amlogic S905D），如需刷机，可直接下载 [releases](https://github.com/yao1987825/Cloud-N1-OpenWrt/releases/latest) 内固件。

---

## 编译配置

**目标架构**：
- Target System: `armsr` (ARM Standalone)
- Subtarget: `armv8` (64-bit ARM)
- 默认串口: `ttyS0`

**添加编译**（默认未勾选，自选！）
  - [x] `luci-app-docker`
  - [x] `luci-app-dockerman`
  - [x] `luci-theme-opentomcat`
  - [x] `luci-app-adguardhome`
  - [x] `luci-app-amlogic`

**默认编译**（默认勾选，未取消！）
  - [x] `luci-app-autoreboot`
  - [x] `luci-app-filetransfer`
  - [x] `luci-app-nlbwmon`
  - [x] `luci-app-ssr-plus`
    - [x] `Include ChinaDNS-NG`
    - [x] `Include MosDNS`
    - [x] `Include Shadowsocks Simple Obfs Plugin`
    - [x] `Include ShadowsocksR Libev Client`
  - [x] `luci-app-vlmcsd`
  - [x] `luci-app-wol`

**强制编译**（默认勾选，无法取消！）
  - [x] `luci-app-firewall`

**精简编译**（默认勾选，取消！）
  - [x] `luci-app-accesscontrol`
  - [x] `luci-app-arpbind`
  - [x] `luci-app-ddns`
  - [x] `luci-app-turboacc`
  - [x] `UnblockNeteaseMusic Golang Version`
  - [x] `luci-app-upnp`
  - [x] `luci-app-vsftpd`

---

## 脚本文件说明

### `script.sh` - 自定义包安装

从外部仓库克隆额外的 LuCI 插件：

| 包名 | 来源 | 说明 |
|------|------|------|
| `luci-app-adguardhome` | `rufengsuixing/luci-app-adguardhome` | AdGuard Home 管理界面 |
| `luci-theme-opentomcat` | `Leo-Jo-My/luci-theme-opentomcat` | OpenTomcat 主题 |
| `luci-app-amlogic` | `ophub/luci-app-amlogic` | Amlogic 设备管理工具 |

### `config.sh` - 编译后配置修补

编译过程中需要动态修补的问题：

| 问题 | 修复方式 |
|------|----------|
| ksmbd 3.5.4 与内核 6.12 不兼容 | `rm -rf package/kernel/ksmbd` + sed 禁用相关包 |
| armsr 默认输出 `combined-efi.img.gz` 需要 grub | patch `armsr/image/Makefile` 移除 combined-efi 输出 |

---

## 遇到的问题及解决方案

### 问题 1：LEDE 上游 armvirt → armsr 重命名

**现象**：`target/linux/armvirt/` 目录不存在，`.config` 中 `CONFIG_TARGET_armvirt_64=y` 无效。

**原因**：LEDE 上游（`coolsnowwolf/lede`）在 2026 年将 `armvirt` 重命名为 `armsr`（ARM Standalone），同时 `armvirt_64` 变为 `armsr_armv8`。

**修复**：
- `.config` 中 `BOARD` 从 `armvirt` 改为 `armsr`
- `SUBTARGET` 从 `64` 改为 `armv8`
- `subtarget config` 从 `armvirt_64` 改为 `armsr_armv8`
- `Organize files` 步骤中的 `rm` 命令更新文件名匹配 `armsr`

### 问题 2：ksmbd 与内核 6.12 不兼容

**现象**：编译时 ksmbd 3.5.4 报错，与内核 6.12 存在 API 不兼容。

**原因**：Lean 源码默认启用 ksmbd，但上游版本较旧，与新内核 API 不兼容。

**修复**：在 `config.sh` 中删除 ksmbd 包目录并禁用相关配置选项。

### 问题 3：combined-efi.img.gz 编译失败

**现象**：`mkfs.fat: file ...img.gz.kernel already exists`，编译中断。

**原因**：armsr target 默认输出 `combined-efi.img.gz`（EFI 启动镜像），需要 `grub2-efi-arm` 提供 boot 内容。但 N1 使用 Amlogic Boot，不需要 EFI。

**修复**：在 `config.sh` 中 patch `armsr/image/Makefile`，移除 `combined-efi` 相关输出行。

### 问题 4：rootfs.tar.gz 缺失

**现象**：flippy 打包时找不到 `openwrt-armsr-armv8-generic-rootfs.tar.gz`。

**原因**：`.config` 中 `CONFIG_TARGET_ROOTFS_TARGZ` 默认关闭，而 flippy 需要 `.tar.gz` 格式的 rootfs。

**修复**：在 `.config` 中启用 `CONFIG_TARGET_ROOTFS_TARGZ=y`。

### 问题 5：LEDE 上游 armvirt/armv8 Makefile 缺失

**现象**：`target/linux/armvirt/image/Makefile` 不存在，导致 `sed` patch 失败。

**原因**：armsr 目录结构与旧 armvirt 不同，`armvirt/image/Makefile` 已被 `armsr/image/Makefile` 替代。

**修复**：确认使用正确的文件路径 `target/linux/armsr/image/Makefile`。

### 问题 6：Makefile 中 `include` 路径不匹配

**现象**：`sed: can't read target/linux/armvirt/image/Makefile: No such file or directory`

**原因**：在 `sed` 命令中使用了旧的 `armvirt` 路径，而实际文件位于 `armsr` 目录。

**修复**：将 `sed` 命令中的路径从 `armvirt` 更新为 `armsr`。

---

## 编译流程

```
GitHub Actions 触发 (push/schedule/dispatch)
    ↓
Free Disk Space (清理不必要的工具)
    ↓
Clone source code (coolsnowwolf/lede)
    ↓
Update feeds + Install custom packages (script.sh)
    ↓
Load custom configuration (.config + config.sh)
    ↓
make defconfig → make download → make -j$(nproc)
    ↓
Resolve latest kernel version (breakingbadboy/OpenWrt)
    ↓
Flippy 打包 N1 镜像 (openwrt_s905d_n1_*.img.gz)
    ↓
Organize files + Upload artifact
    ↓
Create release (GitHub Release)
```

---

## 刷机信息

- **默认 IP**: `192.168.6.1`
- **默认用户名**: `root`
- **默认密码**: `3971247`

---

## 感谢 ❤️
- 源码来源： Lean 的 Openwrt 源码仓库 https://github.com/coolsnowwolf/lede
- 脚本来源： P3TERX 的 使用 GitHub Actions 云编译 OpenWrt https://github.com/P3TERX/Actions-OpenWrt
- 打包脚本： Flippy 的 OpenWrt 打包脚本 Actions https://github.com/ophub/flippy-openwrt-actions

---

## 更新日志

### 2026-09-12
- 默认IP由 `192.168.1.1` 修改为 `192.168.6.1`（`.config` 中 `CONFIG_TARGET_PREINIT_IP`）
- 默认密码由 `password` 修改为 `3971247`（通过 `files/etc/shadow` 预置）
- 修改涉及文件：
  - `.config`: `CONFIG_TARGET_PREINIT_IP="192.168.6.1"`, `CONFIG_TARGET_PREINIT_BROADCAST="192.168.6.255"`
  - `files/etc/shadow`: 预置 root 密码哈希
- 修正 armvirt → armsr 架构重命名问题
- 修复 ksmbd 与内核 6.12 不兼容
- 修复 combined-efi.img.gz 编译失败
- 启用 rootfs.tar.gz 输出
- 启用 USB 网卡驱动 (cdc-ether, rndis)
- 修复 release-action token 未设置错误

### 20260515
- 修改打包脚本，获取实际内核版本，输出到 release 说明

### 20250424
- 修正底层编译环境 `Ubuntu 20.04` 弃用造成的编译错误

### 20250303
- 修正 `actions/upload-artifact` 版本升级造成的编译错误

### 20240224
- 更新配置

### 20231129
- 更新内核版本 6.1.63，删除失效的插件

### 20231015
- 更新内核版本 6.1.57，集成 `PassWall`

### 20230915
- 修正 Github Action 空间不足导致的打包失败，更新内核版本 6.1.52

### 20230619
- 修正 Github Action 空间不足导致的打包失败，更新内核版本 6.1.34

### 20230211
- 修正 `set-output` 有效性造成的编译错误，更新内核版本 6.1.10

### 20221031
- 更新内核版本 6.0.6

### 20220814
- 更新内核版本 5.19.1

### 20220731
- 更新内核版本 5.18.15

### 20220620
- 更新内核版本 5.18.5

### 20220509
- 更新配置，更新内核版本 5.17.5

### 20220428
- 添加自动打包命令，生成刷机固件

### 20220427
- 更新配置，Release 默认保留3个

### 20210827
- 更新配置

### 20210210
- 修正源码更新造成的编译错误，集成 `docker`

### 20201124
- 修正 `set-env` 有效性造成的编译错误

### 20200926
- 修正 `openclash` 编译错误
