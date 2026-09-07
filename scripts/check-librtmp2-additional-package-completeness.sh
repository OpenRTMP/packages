#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
ROOT_DIR="${ROOT_DIR:-$PWD}"

usage() {
    echo "Usage: $0 <rpm|arch|homebrew|windows>" >&2
    exit 2
}

check_file() {
    local path="$1"
    if [[ ! -f "$ROOT_DIR/$path" ]]; then
        echo "Missing: $path"
        return 1
    fi
}

check_glob() {
    local pattern="$1"
    if ! compgen -G "$ROOT_DIR/$pattern" > /dev/null; then
        echo "Missing: $pattern"
        return 1
    fi
}

check_rpm() {
    local missing=0
    local target family release release_tag arch base
    local -a targets=(
        "fedora:44:fc44"
        "el:9:el9"
        "el:10:el10"
        "opensuse:16.0:suse160"
    )
    local -a arches=(x86_64 aarch64 ppc64le s390x)

    for target in "${targets[@]}"; do
        IFS=: read -r family release release_tag <<< "$target"
        for arch in "${arches[@]}"; do
            base="rpm/$family/$release/$arch"
            check_glob "$base/librtmp2-${VERSION}-1.${release_tag}.${arch}.rpm" || missing=1
            check_glob "$base/librtmp2-devel-${VERSION}-1.${release_tag}.${arch}.rpm" || missing=1
            check_file "$base/repodata/repomd.xml" || missing=1
            check_file "$base/repodata/repomd.xml.asc" || missing=1
        done
    done

    if (( missing != 0 )); then
        echo "RPM repositories for librtmp2 $VERSION are incomplete."
        return 1
    fi

    echo "RPM repositories for librtmp2 $VERSION are complete."
}

check_arch() {
    local missing=0
    local base="arch/x86_64"
    local package="$base/librtmp2-${VERSION}-1-x86_64.pkg.tar.zst"

    check_file "$package" || missing=1
    check_file "$package.sig" || missing=1
    check_file "$base/openrtmp.db" || missing=1
    check_file "$base/openrtmp.db.sig" || missing=1
    check_file "$base/openrtmp.db.tar.gz" || missing=1
    check_file "$base/openrtmp.db.tar.gz.sig" || missing=1
    check_file "$base/openrtmp.files" || missing=1
    check_file "$base/openrtmp.files.sig" || missing=1
    check_file "$base/openrtmp.files.tar.gz" || missing=1
    check_file "$base/openrtmp.files.tar.gz.sig" || missing=1

    if (( missing != 0 )); then
        echo "Arch Linux repository for librtmp2 $VERSION is incomplete."
        return 1
    fi

    echo "Arch Linux repository for librtmp2 $VERSION is complete."
}

check_homebrew() {
    if [[ ! -f "$ROOT_DIR/Formula/librtmp2.rb" ]] \
        || ! grep -Fq "/releases/download/v${VERSION}/librtmp2-${VERSION}-src.tar.gz" "$ROOT_DIR/Formula/librtmp2.rb"; then
        echo "Homebrew formula for librtmp2 $VERSION is incomplete."
        return 1
    fi

    echo "Homebrew formula for librtmp2 $VERSION is complete."
}

check_windows() {
    local missing=0
    local arch base package
    local -a arches=(x86_64 arm64)

    for arch in "${arches[@]}"; do
        base="windows/$arch/$VERSION"
        package="$base/librtmp2-${VERSION}-windows-${arch}.zip"

        check_file "$package" || missing=1
        check_file "$package.sha256" || missing=1
        check_file "$package.asc" || missing=1
    done

    if (( missing != 0 )); then
        echo "Windows packages for librtmp2 $VERSION are incomplete."
        return 1
    fi

    echo "Windows packages for librtmp2 $VERSION are complete."
}

case "${1:-}" in
    rpm) check_rpm ;;
    arch) check_arch ;;
    homebrew) check_homebrew ;;
    windows) check_windows ;;
    *) usage ;;
esac
