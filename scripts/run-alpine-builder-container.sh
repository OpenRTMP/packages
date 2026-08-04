#!/bin/sh
set -eu

: "${VERSION:?VERSION is required}"
: "${ALPINE_BRANCH:?ALPINE_BRANCH is required}"
: "${OUTPUT_DIR:?OUTPUT_DIR is required}"

apk add --no-cache \
  alpine-sdk \
  bash \
  ca-certificates \
  curl \
  git \
  openssl-dev \
  pkgconf \
  sudo

apk add --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
  rust \
  cargo

rustc --version
cargo --version

adduser -D builder
addgroup builder abuild
printf '%s\n' 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder

mkdir -p /home/builder/.abuild
cp /keys/openrtmp-alpine.rsa /home/builder/.abuild/openrtmp-alpine.rsa
cp /keys/openrtmp-alpine.rsa.pub /home/builder/.abuild/openrtmp-alpine.rsa.pub
cp /keys/openrtmp-alpine.rsa.pub /etc/apk/keys/openrtmp-alpine.rsa.pub

cat > /home/builder/.abuild/abuild.conf <<'EOF'
PACKAGER="OpenRTMP <info@openrtmp.org>"
PACKAGER_PRIVKEY="/home/builder/.abuild/openrtmp-alpine.rsa"
EOF

chown -R builder:builder /home/builder "$OUTPUT_DIR"

exec su builder -c \
  "VERSION='$VERSION' ALPINE_BRANCH='$ALPINE_BRANCH' OUTPUT_DIR='$OUTPUT_DIR' WORK_DIR='/home/builder/apk-work' /workspace/scripts/build-librtmp2-apk.sh"
