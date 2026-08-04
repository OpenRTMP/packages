#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
POOL_DIR="$ROOT_DIR/pool/main/l/librtmp2"
DIST_DIR="$ROOT_DIR/dists"
ARCHITECTURE="${ARCHITECTURE:-amd64}"
CODENAMES=(bookworm trixie jammy noble)

mkdir -p "$POOL_DIR" "$DIST_DIR"

for codename in "${CODENAMES[@]}"; do
    binary_dir="$DIST_DIR/$codename/main/binary-$ARCHITECTURE"
    temp_dir="$(mktemp -d)"
    mkdir -p "$binary_dir"

    find "$POOL_DIR" -maxdepth 1 -type f \
        -name "*+${codename}1_${ARCHITECTURE}.deb" \
        -exec cp {} "$temp_dir/" \;

    if compgen -G "$temp_dir/*.deb" > /dev/null; then
        dpkg-scanpackages --multiversion "$temp_dir" /dev/null \
            | sed "s#Filename: $temp_dir/#Filename: pool/main/l/librtmp2/#" \
            > "$binary_dir/Packages"
    else
        : > "$binary_dir/Packages"
    fi

    gzip -9c "$binary_dir/Packages" > "$binary_dir/Packages.gz"
    rm -rf "$temp_dir"

    release_tmp="$(mktemp)"
    apt-ftparchive release "$DIST_DIR/$codename" > "$release_tmp"
    {
        echo "Origin: OpenRTMP"
        echo "Label: OpenRTMP"
        echo "Suite: $codename"
        echo "Codename: $codename"
        echo "Architectures: $ARCHITECTURE"
        echo "Components: main"
        echo "Description: OpenRTMP APT repository"
        cat "$release_tmp"
    } > "$DIST_DIR/$codename/Release"
    rm -f "$release_tmp"
done
