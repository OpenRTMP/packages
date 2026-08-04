#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
POOL_DIR="$ROOT_DIR/pool/main/l/librtmp2"
DIST_DIR="$ROOT_DIR/dists"
CODENAMES=(bookworm trixie jammy noble resolute)
ARCHITECTURES=(amd64 arm64 armhf i386 ppc64el riscv64 s390x)

mkdir -p "$POOL_DIR" "$DIST_DIR"

for codename in "${CODENAMES[@]}"; do
    available_architectures=()

    for architecture in "${ARCHITECTURES[@]}"; do
        binary_dir="$DIST_DIR/$codename/main/binary-$architecture"
        temp_dir="$(mktemp -d)"
        mkdir -p "$binary_dir"

        find "$POOL_DIR" -maxdepth 1 -type f \
            -name "*+${codename}1_${architecture}.deb" \
            -exec cp {} "$temp_dir/" \;

        if compgen -G "$temp_dir/*.deb" > /dev/null; then
            dpkg-scanpackages --multiversion "$temp_dir" /dev/null \
                | sed "s#Filename: $temp_dir/#Filename: pool/main/l/librtmp2/#" \
                > "$binary_dir/Packages"
            available_architectures+=("$architecture")
        else
            : > "$binary_dir/Packages"
        fi

        gzip -9c "$binary_dir/Packages" > "$binary_dir/Packages.gz"
        rm -rf "$temp_dir"
    done

    if [[ ${#available_architectures[@]} -eq 0 ]]; then
        echo "No packages found for $codename." >&2
        exit 1
    fi

    release_tmp="$(mktemp)"
    apt-ftparchive release "$DIST_DIR/$codename" > "$release_tmp"
    {
        echo "Origin: OpenRTMP"
        echo "Label: OpenRTMP"
        echo "Suite: $codename"
        echo "Codename: $codename"
        echo "Architectures: ${available_architectures[*]}"
        echo "Components: main"
        echo "Description: OpenRTMP APT repository"
        cat "$release_tmp"
    } > "$DIST_DIR/$codename/Release"
    rm -f "$release_tmp"
done
