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

**任务目标**：将默认LAN IP从 `192.168.1.1` 改为 `10.10.10.250`

**修改内容**：
- 创建 `files/etc/config/network` 配置文件
- LAN IP: `10.10.10.250`
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

**备注**：修改此文档时请保持格式一致，方便后续查阅。
