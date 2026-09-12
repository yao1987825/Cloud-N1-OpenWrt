#!/bin/bash
cd openwrt

# Add luci-app-adguardhome
rm -rf package-temp/luci-app-adguardhome
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package-temp/luci-app-adguardhome
mv -f package-temp/luci-app-adguardhome package/lean/
rm -rf package-temp

# Add luci-theme-opentomcat
rm -rf theme-temp/luci-theme-opentomcat
git clone https://github.com/Leo-Jo-My/luci-theme-opentomcat.git theme-temp/luci-theme-opentomcat
rm -rf theme-temp/luci-theme-opentomcat/LICENSE
rm -rf theme-temp/luci-theme-opentomcat/README.md
mv -f theme-temp/luci-theme-opentomcat package/lean/
rm -rf theme-temp
default_theme='opentomcat'
luci_default_config=$(find feeds/luci -path '*luci-base/root/etc/config/luci' 2>/dev/null | head -n 1)
if [[ -n "$luci_default_config" ]]; then
  sed -i "s/bootstrap/$default_theme/g" "$luci_default_config"
else
  echo "luci-base default config not found, skip default theme switch"
fi

# Add luci-app-amlogic
rm -rf package-temp/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic.git package-temp/luci-app-amlogic
mv -f package-temp/luci-app-amlogic/luci-app-amlogic package/lean/
rm -rf package-temp