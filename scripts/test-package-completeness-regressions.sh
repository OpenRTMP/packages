#!/usr/bin/env bash
# Regression tests for matching package versions/signatures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APT_CHECK="$REPO_ROOT/scripts/check-librtmp2-package-completeness.sh"
OTHER_CHECK="$REPO_ROOT/scripts/check-librtmp2-additional-package-completeness.sh"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

export VERSION=0.17.1 ROOT_DIR="$TEMP_DIR"

expect_pass() {
    if ! "$@" > "$TEMP_DIR/result.log" 2>&1; then
        cat "$TEMP_DIR/result.log" >&2
        echo "Expected success: $*" >&2
        exit 1
    fi
}

expect_fail() {
    if "$@" > "$TEMP_DIR/result.log" 2>&1; then
        echo "Expected failure: $*" >&2
        exit 1
    fi
}

# Match the architectures listed by the real APT checker so the complete
# synthetic repository fixture stays in sync with supported target series.
mapfile -t targets < <(
    sed -n '/^    local -a targets=(/,/^    )/p' "$APT_CHECK" |
        sed -n 's/^        "\([^"]*\)".*/\1/p'
)
[[ "${#targets[@]}" -gt 0 ]] || { echo "No APT targets found" >&2; exit 1; }

for target in "${targets[@]}"; do
    IFS=: read -r family codename arch <<< "$target"
    pool="$TEMP_DIR/$family/pool/main/l/librtmp2"
    binaries="$TEMP_DIR/$family/dists/$codename/main/binary-$arch"
    release="$TEMP_DIR/$family/dists/$codename"
    mkdir -p "$pool" "$binaries"
    touch "$pool/librtmp2_${VERSION}-1~${codename}1_${arch}.deb"
    touch "$pool/librtmp2-dev_${VERSION}-1~${codename}1_${arch}.deb"
    touch "$binaries/Packages" "$binaries/Packages.gz"
    touch "$release/Release" "$release/InRelease" "$release/Release.gpg"
done

expect_pass bash "$APT_CHECK" apt

# Mismatched revisions must not count as a complete installable pair.
apt_pool="$TEMP_DIR/debian/pool/main/l/librtmp2"
rm "$apt_pool/librtmp2-dev_${VERSION}-1~trixie1_amd64.deb"
touch "$apt_pool/librtmp2-dev_${VERSION}-2~trixie1_amd64.deb"
expect_fail bash "$APT_CHECK" apt

# A second, complete revision is allowed even with an older runtime remaining.
touch "$apt_pool/librtmp2_${VERSION}-2~trixie1_amd64.deb"
expect_pass bash "$APT_CHECK" apt

# Legacy +codename pairs must remain supported after the version migration.
rm "$apt_pool"/librtmp2{,-dev}_"${VERSION}"-*trixie1_amd64.deb
touch "$apt_pool/librtmp2_${VERSION}-1+trixie1_amd64.deb"
touch "$apt_pool/librtmp2-dev_${VERSION}-1+trixie1_amd64.deb"
expect_pass bash "$APT_CHECK" apt

# Alpine: runtime, dev, and static must share one pkgrel. dev and static pin
# the runtime with an exact pkgver-pkgrel dependency.
for branch in v3.21 v3.22 v3.23 v3.24 edge; do
    for arch in x86_64 x86 aarch64 armv7 ppc64le riscv64 s390x; do
        alpine_base="$TEMP_DIR/alpine/$branch/main/$arch"
        mkdir -p "$alpine_base"
        touch "$alpine_base/librtmp2-${VERSION}-r0.apk" \
              "$alpine_base/librtmp2-dev-${VERSION}-r0.apk" \
              "$alpine_base/librtmp2-static-${VERSION}-r0.apk" \
              "$alpine_base/APKINDEX.tar.gz"
    done
done
expect_pass bash "$APT_CHECK" alpine

alpine_base="$TEMP_DIR/alpine/edge/main/s390x"
rm "$alpine_base/librtmp2-dev-${VERSION}-r0.apk"
touch "$alpine_base/librtmp2-dev-${VERSION}-r1.apk"
expect_fail bash "$APT_CHECK" alpine

touch "$alpine_base/librtmp2-${VERSION}-r1.apk" \
      "$alpine_base/librtmp2-static-${VERSION}-r1.apk"
expect_pass bash "$APT_CHECK" alpine

# RPM: librtmp2-devel requires the exact runtime version-release. A runtime
# and devel from different releases are not an installable pair.
for target in fedora:44:fc44 el:9:el9 el:10:el10 opensuse:16.0:suse160; do
    IFS=: read -r family release release_tag <<< "$target"
    for arch in x86_64 aarch64 ppc64le s390x; do
        rpm_base="$TEMP_DIR/rpm/$family/$release/$arch"
        mkdir -p "$rpm_base/repodata"
        touch "$rpm_base/librtmp2-${VERSION}-1.${release_tag}.${arch}.rpm" \
              "$rpm_base/librtmp2-devel-${VERSION}-1.${release_tag}.${arch}.rpm" \
              "$rpm_base/repodata/repomd.xml" \
              "$rpm_base/repodata/repomd.xml.asc"
    done
done
expect_pass bash "$OTHER_CHECK" rpm

rpm_base="$TEMP_DIR/rpm/opensuse/16.0/s390x"
rm "$rpm_base/librtmp2-devel-${VERSION}-1.suse160.s390x.rpm"
touch "$rpm_base/librtmp2-devel-${VERSION}-2.suse160.s390x.rpm"
expect_fail bash "$OTHER_CHECK" rpm

touch "$rpm_base/librtmp2-${VERSION}-2.suse160.s390x.rpm"
expect_pass bash "$OTHER_CHECK" rpm

arch_repo="$TEMP_DIR/arch/x86_64"
mkdir -p "$arch_repo"
for name in openrtmp.db openrtmp.db.sig openrtmp.db.tar.gz \
            openrtmp.db.tar.gz.sig openrtmp.files openrtmp.files.sig \
            openrtmp.files.tar.gz openrtmp.files.tar.gz.sig; do
    touch "$arch_repo/$name"
done

archive="$arch_repo/librtmp2-${VERSION}-2-x86_64.pkg.tar.zst"
touch "$archive" "$arch_repo/librtmp2-${VERSION}-1-x86_64.pkg.tar.zst.sig"
expect_fail bash "$OTHER_CHECK" arch

touch "$archive.sig"
expect_pass bash "$OTHER_CHECK" arch

rm "$archive"
expect_fail bash "$OTHER_CHECK" arch

echo "Package completeness regression tests passed."
