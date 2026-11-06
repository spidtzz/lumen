#!/usr/bin/env bash
# Download Space Grotesk (SIL Open Font License) into assets/fonts/.
# Space Grotesk isn't in the official Arch repositories, so lumen ships it.
# Run once and commit the result; install.sh also runs this if it's missing.
set -euo pipefail
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/fonts
base=https://github.com/google/fonts/raw/main/ofl/spacegrotesk
mkdir -p "$dir"
curl -fsSL --retry 2 -o "$dir/SpaceGrotesk[wght].ttf" "$base/SpaceGrotesk%5Bwght%5D.ttf"
curl -fsSL --retry 2 -o "$dir/OFL.txt" "$base/OFL.txt"
echo "Space Grotesk saved to $dir"
