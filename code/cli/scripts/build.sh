#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cli_root="$(cd "$script_dir/.." && pwd)"
build_dir="$cli_root/build"

rm -rf "$build_dir"
mkdir -p "$build_dir/bin"

echo '>>> Compiling post-publisher...'
(
  cd "$cli_root"
  dart compile exe bin/main.dart -o "$build_dir/bin/post-publisher"
)

if [[ -d "$cli_root/assets" ]]; then
  echo '>>> Copying assets...'
  cp -R "$cli_root/assets" "$build_dir/assets"
fi

echo '>>> Build complete.'
echo "    Binary: $build_dir/bin/post-publisher"