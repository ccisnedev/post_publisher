#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cli_root="$(cd "$script_dir/.." && pwd)"
build_dir="$cli_root/build"
install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/post_publisher"
bin_dir="$install_dir/bin"

echo '>>> Building from source...'
"$script_dir/build.sh"

rm -rf "$install_dir"
mkdir -p "$bin_dir"

cp "$build_dir/bin/linkedin" "$bin_dir/linkedin"
chmod +x "$bin_dir/linkedin"

if [[ -d "$build_dir/assets" ]]; then
  cp -R "$build_dir/assets" "$install_dir/assets"
fi

echo ''
echo '>>> Installed from source successfully!'
echo "    Add $bin_dir to your PATH if needed."