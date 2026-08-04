#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
CODENAME="${CODENAME:?CODENAME is required}"
SOURCE_DIR="${SOURCE_DIR:-$PWD/librtmp2}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"
ARCH="$(dpkg --print-architecture)"
PACKAGE_VERSION="${VERSION}-1+${CODENAME}1"
MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"

mkdir -p "$OUTPUT_DIR"
cd "$SOURCE_DIR"

if [[ ! -f include/librtmp2/librtmp2.h ]]; then
    cargo install --locked cbindgen
    mkdir -p include/librtmp2
    cbindgen --config cbindgen.toml --crate librtmp2 --output include/librtmp2/librtmp2.h
fi

cargo build --release --locked

RUNTIME_ROOT="$(mktemp -d)"
DEV_ROOT="$(mktemp -d)"
trap 'rm -rf "$RUNTIME_ROOT" "$DEV_ROOT"' EXIT

install -Dm755 target/release/librtmp2.so \
    "$RUNTIME_ROOT/usr/lib/$MULTIARCH/librtmp2.so"

mkdir -p "$RUNTIME_ROOT/DEBIAN"
cat > "$RUNTIME_ROOT/DEBIAN/control" <<EOF
Package: librtmp2
Version: $PACKAGE_VERSION
Section: libs
Priority: optional
Architecture: $ARCH
Maintainer: OpenRTMP <info@openrtmp.org>
Depends: libc6, libssl3
Homepage: https://github.com/OpenRTMP/librtmp2
Description: RTMP and RTMPS protocol library
 librtmp2 provides Legacy RTMP and Enhanced RTMP support through a native
 shared library and stable C-compatible FFI.
EOF

install -Dm644 target/release/librtmp2.a \
    "$DEV_ROOT/usr/lib/$MULTIARCH/librtmp2.a"
install -Dm644 include/librtmp2/librtmp2.h \
    "$DEV_ROOT/usr/include/librtmp2/librtmp2.h"

mkdir -p "$DEV_ROOT/usr/lib/$MULTIARCH/pkgconfig"
cat > "$DEV_ROOT/usr/lib/$MULTIARCH/pkgconfig/librtmp2.pc" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib/$MULTIARCH
includedir=\${prefix}/include

Name: librtmp2
Description: RTMP and RTMPS protocol library
Version: $VERSION
Libs: -L\${libdir} -lrtmp2
Cflags: -I\${includedir}/librtmp2
EOF

mkdir -p "$DEV_ROOT/DEBIAN"
cat > "$DEV_ROOT/DEBIAN/control" <<EOF
Package: librtmp2-dev
Version: $PACKAGE_VERSION
Section: libdevel
Priority: optional
Architecture: $ARCH
Maintainer: OpenRTMP <info@openrtmp.org>
Depends: librtmp2 (= $PACKAGE_VERSION)
Homepage: https://github.com/OpenRTMP/librtmp2
Description: Development files for librtmp2
 This package contains the C header, static library, and pkg-config metadata
 required to build software against librtmp2.
EOF

RUNTIME_DEB="$OUTPUT_DIR/librtmp2_${PACKAGE_VERSION}_${ARCH}.deb"
DEV_DEB="$OUTPUT_DIR/librtmp2-dev_${PACKAGE_VERSION}_${ARCH}.deb"

dpkg-deb --root-owner-group --build "$RUNTIME_ROOT" "$RUNTIME_DEB"
dpkg-deb --root-owner-group --build "$DEV_ROOT" "$DEV_DEB"

dpkg-deb --info "$RUNTIME_DEB"
dpkg-deb --info "$DEV_DEB"
