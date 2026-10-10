#!/usr/bin/env bash
# Install the freshly built librtmp2 packages from OUTPUT_DIR and check that a
# C program can be compiled against them with pkg-config and run with the
# installed shared library.
set -euo pipefail

VERSION="${VERSION:?VERSION is required}"
CODENAME="${CODENAME:?CODENAME is required}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"
ARCH="$(dpkg --print-architecture)"
PACKAGE_VERSION="${VERSION}-1+${CODENAME}1"
RUNTIME_DEB="$OUTPUT_DIR/librtmp2_${PACKAGE_VERSION}_${ARCH}.deb"
DEV_DEB="$OUTPUT_DIR/librtmp2-dev_${PACKAGE_VERSION}_${ARCH}.deb"

# apt resolves the packages' Depends against the distribution archive, so an
# uninstallable dependency fails here instead of on users' systems.
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "$RUNTIME_DEB" "$DEV_DEB"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cat > "$WORK_DIR/smoke.c" <<'C'
#include <stdio.h>
#include <string.h>
#include <librtmp2.h>

int main(int argc, char **argv) {
    const char *version = lrtmp2_version_string();
    if (argc != 2 || version == NULL || strcmp(version, argv[1]) != 0) {
        fprintf(stderr, "unexpected librtmp2 version: %s\n", version ? version : "(null)");
        return 1;
    }
    printf("librtmp2 %s\n", version);
    return 0;
}
C

# shellcheck disable=SC2046 # pkg-config output is a list of flags.
cc "$WORK_DIR/smoke.c" -o "$WORK_DIR/smoke" $(pkg-config --cflags --libs librtmp2)
"$WORK_DIR/smoke" "$VERSION"

# /lib may be a symlink to /usr/lib, so compare resolved paths.
linked="$(ldd "$WORK_DIR/smoke" | awk '$1 ~ /^librtmp2\.so/ { print $3 }')"
expected="/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/librtmp2.so"
if [[ -z "$linked" || "$(readlink -f "$linked")" != "$(readlink -f "$expected")" ]]; then
    echo "The smoke test did not load the packaged shared library (got '$linked')." >&2
    exit 1
fi
echo "librtmp2 $PACKAGE_VERSION installs and links on $CODENAME/$ARCH."
