# OpenWrt 项目任务记录

本文档用于记录项目修改、问题排查等任务历史，便于追溯和排查问题。

---

## 任务记录

### 2026-09-18 项目配置检查

**任务目标**：检查项目编译配置，确认WiFi、USB网卡驱动、科学上网插件等配置状态

**检查结果**：

#### 1. GitHub Workflows 配置
- 文件：`.github/workflows/cloud-n1-openwrt.yaml`
- 源码：`coolsnowwolf/lede`
- **默认IP**：`192.168.1.1`
- **默认用户名**：`root`
- **默认密码**：`password`

#### 2. WiFi 功能配置
| 配置项 | 状态 | 说明 |
|--------|------|------|
| `kmod-brcmfmac` | ✅ 已启用 | N1 WiFi 驱动 |
| `brcmfmac-firmware-43455-sdio-phicomm-n1` | ✅ 已启用 | N1 专用 WiFi 固件 |
| `wpad-openssl` | ✅ 已启用 | WiFi 认证支持 |
| `hostapd-common` | ✅ 已启用 | WiFi AP 基础 |
| `kmod-mac80211` | ❌ 未启用 | 802.11 协议栈（可能不需要） |

**结论**：WiFi 功能已配置，但需要确认无线接口是否正常工作。

#### 3. USB 无线网卡驱动
| 配置项 | 状态 | 说明 |
|--------|------|------|
| `kmod-usb-net-rtl8152` | ✅ 已启用 | RTL8152/RTL8153 系列驱动 |
| `kmod-usb-net` | ✅ 已启用 | USB 网络基础 |
| `kmod-usb-net-cdc-ether` | ✅ 已启用 | CDC Ether 支持 |

**结论**：RTL8153b (CPE f50) 驱动已启用，`kmod-usb-net-rtl8152` 支持 RTL8152/RTL8153 系列芯片。

#### 4. 科学上网插件
| 配置项 | 状态 | 说明 |
|--------|------|------|
| `luci-app-ssr-plus` | ❌ 未启用 | SSR Plus 插件 |
| `luci-app-passwall` | ❌ 未启用 | PassWall 插件 |
| `luci-app-openvpn-server` | ❌ 未启用 | OpenVPN 服务端 |

**结论**：科学上网插件（SSR Plus、PassWall）均未启用，需要手动配置开启。

---

### 2026-09-18 预设WiFi密码

**任务目标**：预设WiFi密码为 `3971247`

**修改内容**：
- 创建 `files/etc/config/wireless` 配置文件
- 仅保留5G WiFi: SSID=`OpenWrt`, 密码=`3971247`
- 加密方式: `sae-mixed` (WPA2/WPA3混合模式)
- 移除2.4G WiFi配置

**配置说明**：
- 编译时 `files` 目录会被复制到固件的 `/etc/` 目录
- Workflow步骤: `[ -e files ] && mv files openwrt/files`

---

### 2026-09-18 修改默认IP地址

**任务目标**：将默认LAN IP从 `192.168.1.1` 改为 `10.10.10.1`

**修改内容**：
- 创建 `files/etc/config/network` 配置文件
- LAN IP: `10.10.10.1`
- 子网掩码: `255.255.255.0`

---

### 2026-09-18 启用PassWall插件

**任务目标**：启用luci-app-passwall科学上网插件

**修改内容**：
- `.config` 中启用 `CONFIG_PACKAGE_luci-app-passwall=y`
- 已有子配置（保持不变）：
  - Haproxy: ✅
  - Shadowsocks_Rust_Client: ✅
  - Shadowsocks_Rust_Server: ✅
  - Simple_Obfs: ✅
  - SingBox: ✅
  - V2ray_Geoview: ✅
  - V2ray_Plugin: ✅
  - Xray: ✅

---

### 2026-09-18 推送到GitHub

**任务目标**：将修改推送到GitHub仓库

**修改内容**：
- 提交: `feat: 预设WiFi密码、修改默认IP、启用PassWall`
- Commit: `f38bc09`
- 仓库: https://github.com/yao1987825/Cloud-N1-OpenWrt

---

### 2026-09-18 修复WiFi无法获取IP问题

**问题现象**：WiFi已连接，但设备无法获取IP地址

**问题原因**：缺少 `/etc/config/dhcp` 配置文件，DHCP服务器未正确配置

**修复方案**：
- 创建 `files/etc/config/dhcp` 配置文件
- 为LAN接口启用DHCP服务器
- IP池范围: `10.10.10.100` - `10.10.10.249` (150个地址)
- 租约时间: `12h`

---

### 2026-09-18 修复WiFi SSID被brcmfmac固件覆盖问题

**问题现象**：
- 修改wireless配置的SSID为`OpenWrt-5G`后，刷机后仍显示`phicomm-n1`
- WiFi无法获取IP

**问题原因**：
- 斐讯N1使用BCM43455 WiFi芯片（SDIO接口）
- brcmfmac驱动加载时从`brcmfmac43455-sdio.txt`读取默认SSID配置
- 该txt文件中硬编码了SSID为`phicomm-n1`
- N1的wireless配置被firmware覆盖

**修复方案**：
1. 创建 `files/etc/uci-defaults/99-wireless-fix` 脚本
2. 在首次启动时强制覆盖无线配置
3. 设置SSID为`OpenWrt-5G`，密码`3971247`
4. wifi reload 重新加载配置

---

**备注**：修改此文档时请保持格式一致，方便后续查阅。
