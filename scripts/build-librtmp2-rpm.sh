#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG is required}"
SOURCE_DIR="${SOURCE_DIR:-$PWD/librtmp2}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"

RPM_TOPDIR="$(mktemp -d)"
trap 'rm -rf "$RPM_TOPDIR"' EXIT
mkdir -p "$RPM_TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$OUTPUT_DIR"

cd "$SOURCE_DIR"

if [[ ! -f include/librtmp2/librtmp2.h ]]; then
    cargo install --locked cbindgen
    mkdir -p include/librtmp2
    cbindgen --lang c --cpp-compat --crate librtmp2 \
        --output include/librtmp2/librtmp2.h
fi

# The tagged source archive ships no Cargo.lock (library crates don't
# commit one), so --locked would abort instead of resolving it.
cargo build --release

[[ -f target/release/liblibrtmp2.so ]]
[[ -f target/release/liblibrtmp2.a ]]
[[ -f include/librtmp2/librtmp2.h ]]

LIBDIR="$(rpm --eval '%{_libdir}')"
PC_FILE="$RPM_TOPDIR/SOURCES/librtmp2.pc"
cat > "$PC_FILE" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=$LIBDIR
includedir=\${prefix}/include

Name: librtmp2
Description: RTMP and RTMPS protocol library
Version: $VERSION
Requires.private: openssl
Libs: -L\${libdir} -lrtmp2
Cflags: -I\${includedir}/librtmp2
EOF

SPEC_FILE="$RPM_TOPDIR/SPECS/librtmp2.spec"
cat > "$SPEC_FILE" <<EOF
Name:           librtmp2
Version:        $VERSION
Release:        1.$RELEASE_TAG
Summary:        RTMP and RTMPS protocol library
License:        MIT
URL:            https://github.com/OpenRTMP/librtmp2

%global source_dir $SOURCE_DIR
%global pc_file $PC_FILE

%description
librtmp2 provides Legacy RTMP and Enhanced RTMP support through a native
shared library and stable C-compatible FFI.

%package devel
Summary:        Development files for librtmp2
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers, static library, and pkg-config metadata required to build software
against librtmp2.

%prep

%build

%install
rm -rf %{buildroot}
install -Dm755 %{source_dir}/target/release/liblibrtmp2.so \
    %{buildroot}%{_libdir}/librtmp2.so
install -Dm644 %{source_dir}/target/release/liblibrtmp2.a \
    %{buildroot}%{_libdir}/librtmp2.a
install -Dm644 %{source_dir}/include/librtmp2/librtmp2.h \
    %{buildroot}%{_includedir}/librtmp2/librtmp2.h
install -Dm644 %{pc_file} \
    %{buildroot}%{_libdir}/pkgconfig/librtmp2.pc
install -Dm644 %{source_dir}/LICENSE \
    %{buildroot}%{_licensedir}/librtmp2/LICENSE

%files
%license %{_licensedir}/librtmp2/LICENSE
%{_libdir}/librtmp2.so

%files devel
%{_libdir}/librtmp2.a
%{_libdir}/pkgconfig/librtmp2.pc
%{_includedir}/librtmp2/librtmp2.h

%changelog
* Mon Sep 07 2026 OpenRTMP <info@openrtmp.org> - $VERSION-1.$RELEASE_TAG
- Automated OpenRTMP package build
EOF

rpmbuild --define "_topdir $RPM_TOPDIR" -bb "$SPEC_FILE"

find "$RPM_TOPDIR/RPMS" -type f -name '*.rpm' -print0 | while IFS= read -r -d '' package; do
    cp "$package" "$OUTPUT_DIR/"
done

count="$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.rpm' | wc -l)"
if [[ "$count" -lt 2 ]]; then
    echo "Expected runtime and devel RPM packages, found $count." >&2
    exit 1
fi

for package in "$OUTPUT_DIR"/*.rpm; do
    rpm -qpi "$package"
done
