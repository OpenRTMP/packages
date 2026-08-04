#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_DIR="${1:?repository directory is required}"
shift

if [[ $# -eq 0 ]]; then
    echo "At least one codename is required." >&2
    exit 1
fi

CODENAMES=("$@")
POOL_DIR="$REPOSITORY_DIR/pool/main/l/librtmp2"
DIST_DIR="$REPOSITORY_DIR/dists"
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
            rm -rf "$binary_dir"
        fi

        rm -rf "$temp_dir"
    done

    if [[ ${#available_architectures[@]} -eq 0 ]]; then
        echo "No packages found for $codename in $REPOSITORY_DIR." >&2
        exit 1
    fi

    find "$DIST_DIR/$codename" -type f -name Packages -exec gzip -9cf {} \; >/dev/null
    for packages_file in "$DIST_DIR/$codename"/main/binary-*/Packages; do
        gzip -9c "$packages_file" > "$packages_file.gz"
    done

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
