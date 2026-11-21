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

# Package revisions must match: librtmp2-dev has an exact-version runtime
# dependency. Keep accepting both existing +codename1 and new ~codename1
# packages without mixing revisions between the two.
check_apt_package_pair() {
    local root="$1" codename="$2" arch="$3"
    local pool="$ROOT_DIR/$root/pool/main/l/librtmp2"
    local runtime package_version

    for runtime in "$pool"/librtmp2_"${VERSION}"-*~"${codename}"1_"${arch}".deb \
                   "$pool"/librtmp2_"${VERSION}"-1+"${codename}"1_"${arch}".deb; do
        [[ -f "$runtime" ]] || continue
        package_version="${runtime##*/}"
        package_version="${package_version#librtmp2_}"
        package_version="${package_version%_${arch}.deb}"

        if [[ -f "$pool/librtmp2-dev_${package_version}_${arch}.deb" ]]; then
            return 0
        fi
    done

    echo "Missing matching runtime/development APT package pair: $root/$codename/$arch ($VERSION)"
    return 1
}

check_apt() {
    local missing=0
    local target root codename arch
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
        "ubuntu:stonking:amd64"
        "ubuntu:stonking:arm64"
        "ubuntu:stonking:armhf"
        "ubuntu:stonking:ppc64el"
        "ubuntu:stonking:riscv64"
        "ubuntu:stonking:s390x"
    )

    for target in "${targets[@]}"; do
        IFS=: read -r root codename arch <<< "$target"
        check_apt_package_pair "$root" "$codename" "$arch" || missing=1
        check_file "$root/dists/$codename/main/binary-$arch/Packages" || missing=1
        check_file "$root/dists/$codename/main/binary-$arch/Packages.gz" || missing=1
    done

    for target in "debian:bookworm" "debian:trixie" "ubuntu:jammy" "ubuntu:noble" "ubuntu:resolute" "ubuntu:stonking"; do
        IFS=: read -r root codename <<< "$target"
        check_file "$root/dists/$codename/Release" || missing=1
        check_file "$root/dists/$codename/InRelease" || missing=1
        check_file "$root/dists/$codename/Release.gpg" || missing=1
    done

    if (( missing != 0 )); then
        echo "APT repository for librtmp2 $VERSION is incomplete."
        return 1
    fi

    echo "APT repository for librtmp2 $VERSION is complete."
}

check_alpine() {
    local missing=0
    local branch arch base runtime revision paired
    local -a branches=(v3.21 v3.22 v3.23 v3.24 edge)
    local -a arches=(x86_64 x86 aarch64 armv7 ppc64le riscv64 s390x)

    for branch in "${branches[@]}"; do
        for arch in "${arches[@]}"; do
            base="alpine/$branch/main/$arch"
            paired=false
            # librtmp2-dev and librtmp2-static pin the runtime with an exact
            # pkgver-pkgrel dependency, so a mixed -rN set cannot be installed.
            # Pick one revision that has all three packages.
            for runtime in "$ROOT_DIR/$base"/librtmp2-"${VERSION}"-r*.apk; do
                [[ -f "$runtime" ]] || continue
                revision="${runtime##*/}"
                revision="${revision#librtmp2-${VERSION}-r}"
                revision="${revision%.apk}"
                if [[ -f "$ROOT_DIR/$base/librtmp2-dev-${VERSION}-r${revision}.apk" \
                    && -f "$ROOT_DIR/$base/librtmp2-static-${VERSION}-r${revision}.apk" ]]; then
                    paired=true
                    break
                fi
            done
            if [[ "$paired" != true ]]; then
                echo "Missing matching runtime/development/static APK set: $base ($VERSION)"
                missing=1
            fi
            check_file "$base/APKINDEX.tar.gz" || missing=1
        done
    done

    if (( missing != 0 )); then
        echo "Alpine repository for librtmp2 $VERSION is incomplete."
        return 1
    fi

    echo "Alpine repository for librtmp2 $VERSION is complete."
}

case "${1:-}" in
    apt) check_apt ;;
    alpine) check_alpine ;;
    *) usage ;;
esac
