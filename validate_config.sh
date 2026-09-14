#!/bin/bash
# Validation script for Mercury KM08-708H configuration

set -e

echo "=== Mercury KM08-708H Configuration Validation ==="

# Check if Mercury device is enabled in .config
echo "Checking Mercury device configuration..."
if grep -q "CONFIG_TARGET_ramips_mt7621_DEVICE_mercury_km08-708h=y" .config; then
    echo "✓ Mercury KM08-708H device is enabled"
else
    echo "✗ Mercury KM08-708H device is NOT enabled"
    exit 1
fi

# Check target profile (expanded .config) or seed device line (pre-defconfig).
# `make defconfig` derives CONFIG_TARGET_PROFILE from the single DEVICE_=y,
# so a seed .config legitimately has no PROFILE line at all.
echo "Checking target profile..."
if grep -q 'CONFIG_TARGET_PROFILE="DEVICE_mercury_km08-708h"' .config; then
    echo "✓ Target profile is set to Mercury KM08-708H"
elif ! grep -q '^CONFIG_TARGET_PROFILE=' .config; then
    echo "✓ Seed config (no PROFILE line yet; defconfig derives it from DEVICE_mercury_km08-708h)"
else
    echo "✗ Target profile is NOT set to Mercury KM08-708H"
    exit 1
fi

# Check that Raisecom is disabled (or absent entirely, as in a seed config)
echo "Checking Raisecom device is disabled..."
if grep -q "# CONFIG_TARGET_ramips_mt7621_DEVICE_raisecom_msg1500-x-00 is not set" .config; then
    echo "✓ Raisecom device is properly disabled"
elif ! grep -q "CONFIG_TARGET_ramips_mt7621_DEVICE_raisecom_msg1500-x-00=y" .config; then
    echo "✓ Raisecom device not enabled (seed config)"
else
    echo "✗ Raisecom device might still be enabled"
    exit 1
fi

# Check target architecture (expanded BOARD/SUBTARGET or seed TARGET lines)
echo "Checking target architecture..."
if grep -q "CONFIG_TARGET_BOARD=\"ramips\"" .config && grep -q "CONFIG_TARGET_SUBTARGET=\"mt7621\"" .config; then
    echo "✓ Target architecture is ramips/mt7621 (correct for Mercury KM08-708H)"
elif grep -q "^CONFIG_TARGET_ramips=y" .config && grep -q "^CONFIG_TARGET_ramips_mt7621=y" .config; then
    echo "✓ Target architecture is ramips/mt7621 (seed form)"
else
    echo "✗ Target architecture is incorrect"
    exit 1
fi

# Check USB storage seed (slim policy: USB is the only extra)
echo "Checking USB storage packages..."
USB_OK=true
for pkg in kmod-usb3 kmod-usb-storage kmod-usb-storage-uas block-mount; do
    if grep -q "CONFIG_PACKAGE_${pkg}=y" .config; then
        echo "✓ ${pkg} is enabled"
    else
        echo "✗ ${pkg} is MISSING"
        USB_OK=false
    fi
done
if [ "$USB_OK" = false ]; then
    exit 1
fi

# Check banned packages stay out (slim USB-only policy)
echo "Checking banned packages are absent..."
if grep -Eq "CONFIG_PACKAGE_(xray-core|adblock|sqm-scripts|https-dns-proxy|tailscale)=y" .config; then
    echo "✗ A banned fancy package is enabled (xray/adblock/sqm/doh/tailscale)"
    exit 1
else
    echo "✓ No banned packages (xray/adblock/sqm/doh/tailscale)"
fi

echo ""
echo "=== Configuration Summary ==="
echo "Device: Mercury KM08-708H"
echo "Target: ramips/mt7621"
echo "Profile: DEVICE_mercury_km08-708h"
echo ""
echo "✓ All configurations are correct for Mercury KM08-708H!"
echo "You can now proceed with the build process."