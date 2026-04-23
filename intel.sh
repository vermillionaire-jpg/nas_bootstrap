#!/usr/bin/env bash

# Check for Intel GPU
GPU_INFO=$(lspci | grep -i "VGA\|Display\|3D" | grep -i intel)

if [[ -z "$GPU_INFO" ]]; then
  echo "No Intel GPU detected. Exiting."
  exit 1
fi

echo "Intel GPU detected: $GPU_INFO"

# Extract PCI ID to determine generation
PCI_ID=$(lspci -nn | grep -i "VGA\|Display\|3D" | grep -i intel | grep -oP '8086:\K[0-9a-fA-F]+')

echo "Intel PCI Device ID: $PCI_ID"

# Intel Gen8+ (Broadwell 2014+) device IDs start with:
# 0x1600s = Broadwell (Gen8)
# 0x1900s = Skylake (Gen9)
# 0x3E00s, 0x5900s, 0x3100s = Kaby/Coffee/Gemini (Gen9.5)
# 0x8A00s = Ice Lake (Gen11)
# 0x4C00s, 0x9A00s = Tiger Lake (Gen12)
# 0x4600s, 0x4900s = Alder/Raptor Lake (Gen12+)
MODERN_PREFIXES=("16" "19" "59" "3E" "3e" "31" "8A" "8a" "4C" "4c" "9A" "9a" "46" "49")

IS_MODERN=false
for PREFIX in "${MODERN_PREFIXES[@]}"; do
  if [[ "${PCI_ID^^}" == ${PREFIX^^}* ]]; then
    IS_MODERN=true
    break
  fi
done

if [[ "$IS_MODERN" == false ]]; then
  echo "Intel GPU detected but does not appear to be Gen8+ (Broadwell or newer). Exiting."
  exit 1
fi

echo "Modern Intel iGPU confirmed. Installing VA-API drivers..."

sudo apt-get update
sudo apt-get install -y \
  intel-media-va-driver \
  i965-va-driver \
  vainfo

echo ""
echo "Installation complete. Verifying with vainfo:"
vainfo