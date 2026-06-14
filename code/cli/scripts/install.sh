#!/usr/bin/env bash
set -euo pipefail

repo='ccisnedev/post_publisher'
install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/post_publisher"
bin_dir="$install_dir/bin"
tmp_dir="$(mktemp -d)"
archive="$tmp_dir/linkedin-linux-x64.tar.gz"

echo '>>> Fetching latest release...'
release_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest")"
asset_url="$(printf '%s' "$release_json" | grep -o 'https://[^\"]*linkedin-linux-x64[^\"]*tar.gz' | head -n 1)"

if [[ -z "$asset_url" ]]; then
  echo 'No linkedin-linux-x64 asset found in the latest release.' >&2
  exit 1
fi

echo '>>> Downloading...'
curl -fsSL "$asset_url" -o "$archive"

rm -rf "$install_dir"
mkdir -p "$install_dir"

echo '>>> Extracting...'
tar xzf "$archive" -C "$install_dir"

rm -rf "$tmp_dir"

echo ''
echo '>>> LinkedIn CLI installed successfully!'
echo "    Add $bin_dir to your PATH if needed."