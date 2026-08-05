#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
ALPINE_BRANCH="${ALPINE_BRANCH:?ALPINE_BRANCH is required}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"
WORK_DIR="${WORK_DIR:-$PWD/apk-work}"
REQUIRED_RUST_VERSION="1.93.0"
ARCH="$(apk --print-arch)"

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"
cd "$WORK_DIR"

current_rust_version="$(rustc --version | awk '{print $2}')"
if [[ "$(apk version -t "$current_rust_version" "$REQUIRED_RUST_VERSION")" = "<" ]]; then
    echo "Rust $REQUIRED_RUST_VERSION or newer is required; found $current_rust_version." >&2
    exit 1
fi

command -v rustc
command -v cargo
rustc --version
cargo --version

cat > APKBUILD <<EOF
# Maintainer: OpenRTMP <info@openrtmp.org>
pkgname=librtmp2
pkgver=$VERSION
pkgrel=0
pkgdesc="RTMP and RTMPS protocol library"
url="https://github.com/OpenRTMP/librtmp2"
arch="$ARCH"
license="MIT"
makedepends="openssl-dev pkgconf git curl bash"
subpackages="\$pkgname-dev \$pkgname-static"
source="\$pkgname-\$pkgver.tar.gz::https://github.com/OpenRTMP/librtmp2/archive/refs/tags/v\$pkgver.tar.gz"
builddir="\$srcdir/\$pkgname-\$pkgver"
options="!check net"

prepare() {
    default_prepare
    if [ ! -f include/librtmp2/librtmp2.h ]; then
        cargo install --locked cbindgen
        mkdir -p include/librtmp2
        \$HOME/.cargo/bin/cbindgen \\
            --lang c \\
            --cpp-compat \\
            --crate librtmp2 \\
            --output include/librtmp2/librtmp2.h
    fi
}

build() {
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/liblibrtmp2.so \\
        "\$pkgdir/usr/lib/librtmp2.so.\$pkgver"
    ln -s "librtmp2.so.\$pkgver" "\$pkgdir/usr/lib/librtmp2.so.0"
}

dev() {
    default_dev
    install -Dm644 include/librtmp2/librtmp2.h \\
        "\$subpkgdir/usr/include/librtmp2/librtmp2.h"
    ln -s "librtmp2.so.\$pkgver" "\$subpkgdir/usr/lib/librtmp2.so"
    mkdir -p "\$subpkgdir/usr/lib/pkgconfig"
    cat > "\$subpkgdir/usr/lib/pkgconfig/librtmp2.pc" <<PC
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: librtmp2
Description: RTMP and RTMPS protocol library
Version: \$pkgver
Libs: -L\${libdir} -lrtmp2
Cflags: -I\${includedir}/librtmp2
PC
}

static() {
    pkgdesc="Static library for librtmp2"
    depends="\$pkgname-dev=\$pkgver-r\$pkgrel"
    install -Dm644 target/release/liblibrtmp2.a \\
        "\$subpkgdir/usr/lib/librtmp2.a"
}
EOF

abuild checksum
abuild -r

find "$HOME/packages" -type f -path "*/$ARCH/*.apk" -exec cp {} "$OUTPUT_DIR/" \;

if ! compgen -G "$OUTPUT_DIR/*.apk" > /dev/null; then
    echo "No Alpine packages were produced for $ALPINE_BRANCH/$ARCH" >&2
    exit 1
fi

for package in "$OUTPUT_DIR"/*.apk; do
    apk info --contents --allow-untrusted "$package" >/dev/null
    echo "Built $package"
done
