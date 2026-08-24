#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
PRIVATE_KEY="${ALPINE_PRIVATE_KEY_PATH:?ALPINE_PRIVATE_KEY_PATH is required}"
PUBLIC_KEY="${ALPINE_PUBLIC_KEY_PATH:-$ROOT_DIR/openrtmp-alpine.rsa.pub}"
BRANCHES=(v3.21 v3.22 v3.23 v3.24)
ARCHITECTURES=(x86_64 x86 aarch64 armv7 ppc64le riscv64 s390x)

if [[ ! -f "$PUBLIC_KEY" ]]; then
    echo "Alpine public key not found: $PUBLIC_KEY" >&2
    exit 1
fi

install -Dm644 "$PUBLIC_KEY" "/etc/apk/keys/$(basename "$PUBLIC_KEY")"

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
