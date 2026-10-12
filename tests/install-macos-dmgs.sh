#!/usr/bin/env bash
# Install every HTTP Live Streaming Tools .pkg found in the DMGs under a directory.
# Used by the macOS CI job; needs sudo (GitHub-hosted macOS runners allow it).
set -euo pipefail

dmg_dir="${1:?usage: install-macos-dmgs.sh <directory with .dmg files>}"

shopt -s nullglob
dmgs=("${dmg_dir}"/*.dmg)
if [ "${#dmgs[@]}" -eq 0 ]; then
  echo "No .dmg files in ${dmg_dir}" >&2
  exit 1
fi

for dmg in "${dmgs[@]}"; do
  mount_point="$(mktemp -d /tmp/hlstools-dmg.XXXXXX)"
  echo "== Mounting ${dmg}"
  hdiutil attach "${dmg}" -nobrowse -readonly -mountpoint "${mount_point}" > /dev/null
  pkgs=()
  while IFS= read -r -d '' pkg; do
    pkgs+=("${pkg}")
  done < <(find "${mount_point}" -maxdepth 2 -name '*.pkg' -print0)
  if [ "${#pkgs[@]}" -eq 0 ]; then
    echo "No .pkg installer inside ${dmg}" >&2
    ls -la "${mount_point}" >&2
    hdiutil detach "${mount_point}" > /dev/null
    exit 1
  fi
  for pkg in "${pkgs[@]}"; do
    echo "== Installing ${pkg}"
    sudo installer -pkg "${pkg}" -target /
  done
  hdiutil detach "${mount_point}" > /dev/null
done
