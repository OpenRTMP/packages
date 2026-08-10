#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
ROOT_DIR="${ROOT_DIR:-$PWD}"

usage() {
    echo "Usage: $0 <apt|alpine>" >&2
    exit 2
}

check_file() {
    local path="$1"
    if [[ ! -f "$ROOT_DIR/$path" ]]; then
        echo "Missing: $path"
        return 1
    fi
    return 0
}

check_apt() {
    local missing=0
    local target codename arch root package_version
    local -a targets=(
        "debian:bookworm:amd64"
        "debian:bookworm:arm64"
        "debian:bookworm:armhf"
        "debian:bookworm:i386"
        "debian:bookworm:ppc64el"
        "debian:bookworm:s390x"
        "debian:trixie:amd64"
        "debian:trixie:arm64"
        "debian:trixie:armhf"
        "debian:trixie:i386"
        "debian:trixie:ppc64el"
        "debian:trixie:riscv64"
        "debian:trixie:s390x"
        "ubuntu:jammy:amd64"
        "ubuntu:jammy:arm64"
        "ubuntu:jammy:armhf"
        "ubuntu:jammy:ppc64el"
        "ubuntu:jammy:riscv64"
        "ubuntu:jammy:s390x"
        "ubuntu:noble:amd64"
        "ubuntu:noble:arm64"
        "ubuntu:noble:armhf"
        "ubuntu:noble:ppc64el"
        "ubuntu:noble:riscv64"
        "ubuntu:noble:s390x"
        "ubuntu:resolute:amd64"
        "ubuntu:resolute:arm64"
        "ubuntu:resolute:armhf"
        "ubuntu:resolute:ppc64el"
        "ubuntu:resolute:riscv64"
        "ubuntu:resolute:s390x"
    )

    for target in "${targets[@]}"; do
        IFS=: read -r root codename arch <<< "$target"
        package_version="${VERSION}-1+${codename}1"
        check_file "$root/pool/main/l/librtmp2/librtmp2_${package_version}_${arch}.deb" || missing=1
        check_file "$root/pool/main/l/librtmp2/librtmp2-dev_${package_version}_${arch}.deb" || missing=1
    done

    if (( missing != 0 )); then
        echo "APT packages for librtmp2 $VERSION are incomplete."
        return 1
    fi

    echo "APT packages for librtmp2 $VERSION are complete."
}

check_alpine() {
    local missing=0
    local branch arch base
    local -a branches=(v3.21 v3.22 v3.23 v3.24)
    local -a arches=(x86_64 x86 aarch64 armv7 ppc64le riscv64 s390x)

    for branch in "${branches[@]}"; do
        for arch in "${arches[@]}"; do
            base="alpine/$branch/main/$arch"
            check_file "$base/librtmp2-${VERSION}-r0.apk" || missing=1
            check_file "$base/librtmp2-dev-${VERSION}-r0.apk" || missing=1
            check_file "$base/librtmp2-static-${VERSION}-r0.apk" || missing=1
        done
    done

    if (( missing != 0 )); then
        echo "Alpine packages for librtmp2 $VERSION are incomplete."
        return 1
    fi

    echo "Alpine packages for librtmp2 $VERSION are complete."
}

case "${1:-}" in
    apt) check_apt ;;
    alpine) check_alpine ;;
    *) usage ;;
esac
