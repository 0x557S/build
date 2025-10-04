#!/bin/bash
#
# Custom script for OpenWrt build
# This script runs after feeds configuration and before feeds update
#

set -Eeuo pipefail
IFS=$'\n\t'

trap 'rc=$?; echo "[ERROR] Script failed at line ${LINENO}. Command: ${BASH_COMMAND}" >&2; exit $rc' ERR

log() { echo "[custom] $*"; }
warn() { echo "[custom][WARN] $*" >&2; }

log "================================================"
log "Running custom script..."
log "================================================"

# Current working directory should be openwrt/
log "Current directory: $(pwd)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Git commit: $(git rev-parse --short HEAD)"
else
  warn "Not in a git work tree; skipping commit info"
fi

# Helper: safe in-place sed if file exists
safe_sed() {
  local pattern=$1; shift
  local file=$1; shift || true
  if [[ -f "$file" ]]; then
    log "sed -i on $file: $pattern"
    sed -i "$pattern" "$file"
  else
    warn "File not found, skip sed: $file"
  fi
}

# Helper: git clone with retries
git_clone_retry() {
  local url=$1; shift
  local dest=$1; shift
  local branch=${1:-master}
  local i
  for i in {1..3}; do
    log "Cloning ($i/3): $url -> $dest [branch=$branch]"
    if git clone --depth 1 --branch "$branch" --single-branch "$url" "$dest"; then
      return 0
    fi
    warn "Clone failed ($i). Retrying in 5s..."
    sleep 5
    rm -rf "$dest" || true
  done
  echo "[FATAL] Failed to clone $url after 3 attempts" >&2
  return 1
}

# Example: Add custom feed (disabled by default)
# echo "src-git custom https://github.com/user/custom-packages.git" >> feeds.conf.default

# Example: Modify kernel/device configuration
#if [[ -f "target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts" ]]; then
#  log "Modifying device tree for Cudy TR3000..."
#  sed -i '/reg = <0x4000000/s/0x4000000/0x7000000/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts
#else
#  warn "Device tree not found: target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts"
#fi

safe_sed 's/192.168.1.1/192.168.30.1/g' package/base-files/files/bin/config_generate
safe_sed 's/ImmortalWrt/ASUS/g' package/base-files/files/bin/config_generate
safe_sed 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# External packages
git_clone_retry https://github.com/muink/openwrt-rgmac.git package/rgmac master

git_clone_retry https://github.com/muink/luci-app-change-mac.git package/luci-app-change-mac master
if [[ -d package/luci-app-change-mac/.git ]]; then
  pushd package/luci-app-change-mac >/dev/null
  umask 022
  # Ensure checkout of default branch HEAD (no specific paths)
  git checkout -- .
  popd >/dev/null
else
  warn "package/luci-app-change-mac not a git repo; skip checkout"
fi

# Example: Apply patches (optional)
# PATCH_DIR="${GITHUB_WORKSPACE}/patches"
# if [[ -d "$PATCH_DIR" ]]; then
#   log "Applying custom patches..."
#   for patch in "$PATCH_DIR"/*.patch; do
#     [[ -f "$patch" ]] || continue
#     log "Applying patch: $(basename "$patch")"
#     git apply "$patch" || { warn "Failed to apply $patch"; exit 1; }
#   done
# fi

log "================================================"
log "Custom script completed successfully!"
log "================================================"
