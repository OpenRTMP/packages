#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
PRIVATE_KEY="${ALPINE_PRIVATE_KEY_PATH:?ALPINE_PRIVATE_KEY_PATH is required}"
BRANCHES=(v3.21 v3.22 v3.23 v3.24)
ARCHITECTURES=(x86_64 x86 aarch64 armv7 ppc64le riscv64 s390x)

for branch in "${BRANCHES[@]}"; do
    for arch in "${ARCHITECTURES[@]}"; do
        repo_dir="$ROOT_DIR/alpine/$branch/main/$arch"
        mkdir -p "$repo_dir"

        if compgen -G "$repo_dir/*.apk" > /dev/null; then
            apk index \
                --description "OpenRTMP $branch main" \
                --output "$repo_dir/APKINDEX.tar.gz" \
                "$repo_dir"/*.apk
            abuild-sign -k "$PRIVATE_KEY" "$repo_dir/APKINDEX.tar.gz"
        else
            echo "No packages found for $branch/$arch; skipping index."
        fi
    done
done
