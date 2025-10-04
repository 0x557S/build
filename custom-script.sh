#!/bin/bash
#
# Custom script for OpenWrt build
# This script runs after feeds configuration and before feeds update
#

set -e

echo "================================================"
echo "Running custom script..."
echo "================================================"

# Current working directory should be openwrt/
echo "Current directory: $(pwd)"
echo "Git commit: $(git rev-parse --short HEAD)"

# Example: Add custom feed
# echo "src-git custom https://github.com/user/custom-packages.git" >> feeds.conf.default

sed -i 's/0x4000000/0x7000000/g' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts
sed -i 's/192.168.1.1/192.168.30.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/ASUS/g' package/base-files/files/bin/config_generate
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

git clone --depth 1 --branch master --single-branch https://github.com/muink/openwrt-rgmac.git package/rgmac
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/luci-app-change-mac.git package/luci-app-change-mac
pushd package/luci-app-change-mac
umask 022
git checkout
popd
sed -n -e '20p' -e '25p' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts
# Example: Apply patches
# PATCH_DIR="${GITHUB_WORKSPACE}/patches"
# if [ -d "$PATCH_DIR" ]; then
#     echo "Applying custom patches..."
#     for patch in "$PATCH_DIR"/*.patch; do
#         if [ -f "$patch" ]; then
#             echo "Applying patch: $(basename $patch)"
#             git apply "$patch" || echo "Failed to apply $patch"
#         fi
#     done
# fi

# Example: Clone additional packages
# git clone --depth 1 https://github.com/openwrt/luci.git package/custom-luci || true

# Example: Customize package versions
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=1.2.3/' package/network/services/dnsmasq/Makefile

echo "================================================"
echo "Custom script completed successfully!"
echo "================================================"
