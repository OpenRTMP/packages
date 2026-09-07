#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$OUTPUT_DIR"
cd "$WORK_DIR"

SOURCE_URL="https://github.com/OpenRTMP/librtmp2/archive/refs/tags/v${VERSION}.tar.gz"
curl --fail --location --silent --show-error \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    "$SOURCE_URL" -o "librtmp2-${VERSION}.tar.gz"
SOURCE_SHA256="$(sha256sum "librtmp2-${VERSION}.tar.gz" | awk '{print $1}')"

cat > PKGBUILD <<'PKGBUILD'
pkgname=librtmp2
pkgver=@VERSION@
pkgrel=1
pkgdesc='RTMP and RTMPS protocol library'
arch=('x86_64')
url='https://github.com/OpenRTMP/librtmp2'
license=('MIT')
depends=('glibc' 'openssl')
makedepends=('cargo' 'cbindgen')
source=("librtmp2-${pkgver}.tar.gz::https://github.com/OpenRTMP/librtmp2/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('@SHA256@')
options=('!debug')

build() {
    cd "$srcdir"/librtmp2-*

    if [[ ! -f include/librtmp2/librtmp2.h ]]; then
        mkdir -p include/librtmp2
        cbindgen --lang c --cpp-compat --crate librtmp2 \
            --output include/librtmp2/librtmp2.h
    fi

    cargo build --release --locked
}

package() {
    cd "$srcdir"/librtmp2-*

    install -Dm755 target/release/liblibrtmp2.so \
        "$pkgdir/usr/lib/librtmp2.so"
    install -Dm644 target/release/liblibrtmp2.a \
        "$pkgdir/usr/lib/librtmp2.a"
    install -Dm644 include/librtmp2/librtmp2.h \
        "$pkgdir/usr/include/librtmp2/librtmp2.h"
    install -Dm644 LICENSE \
        "$pkgdir/usr/share/licenses/librtmp2/LICENSE"

    mkdir -p "$pkgdir/usr/lib/pkgconfig"
    cat > "$pkgdir/usr/lib/pkgconfig/librtmp2.pc" <<'EOF'
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: librtmp2
Description: RTMP and RTMPS protocol library
Version: @VERSION@
Libs: -L${libdir} -lrtmp2
Cflags: -I${includedir}/librtmp2
EOF
}
PKGBUILD

sed -i \
    -e "s/@VERSION@/$VERSION/g" \
    -e "s/@SHA256@/$SOURCE_SHA256/g" \
    PKGBUILD

makepkg --clean --cleanbuild --force --noconfirm

package="$(find . -maxdepth 1 -type f -name "librtmp2-${VERSION}-*.pkg.tar.zst" -print -quit)"
[[ -n "$package" ]] || { echo "Arch package was not created." >&2; exit 1; }
cp "$package" "$OUTPUT_DIR/"

bsdtar -xOf "$package" .PKGINFO
