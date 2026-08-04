# OpenRTMP packages

This repository contains separate Debian, Ubuntu, and Alpine package repositories.

```text
.
├── debian/
│   ├── dists/
│   └── pool/main/l/librtmp2/
├── ubuntu/
│   ├── dists/
│   └── pool/main/l/librtmp2/
├── alpine/
│   └── <branch>/main/<architecture>/
├── scripts/
└── .github/workflows/
```

## Debian repository

Supported releases:

- Debian 12 (`bookworm`)
- Debian 13 (`trixie`)

Supported architectures include `amd64`, `arm64`, `armhf`, `i386`, `ppc64el`, `riscv64`, and `s390x` where the selected release provides an official container image.

```bash
echo "deb [signed-by=/usr/share/keyrings/openrtmp.gpg] https://packages.openrtmp.org/debian bookworm main" \
  | sudo tee /etc/apt/sources.list.d/openrtmp.list
```

## Ubuntu repository

Supported releases:

- Ubuntu 22.04 LTS (`jammy`)
- Ubuntu 24.04 LTS (`noble`)
- Ubuntu 26.04 LTS (`resolute`)

Supported architectures are `amd64`, `arm64`, `armhf`, `ppc64el`, `riscv64`, and `s390x`.

```bash
echo "deb [signed-by=/usr/share/keyrings/openrtmp.gpg] https://packages.openrtmp.org/ubuntu noble main" \
  | sudo tee /etc/apt/sources.list.d/openrtmp.list
```

Install the common APT signing key first:

```bash
curl -fsSL https://packages.openrtmp.org/openrtmp.gpg \
  | sudo tee /usr/share/keyrings/openrtmp.gpg >/dev/null

sudo apt update
sudo apt install librtmp2 librtmp2-dev
```

## Alpine repository

Supported branches:

- Alpine 3.21 (`v3.21`)
- Alpine 3.22 (`v3.22`)
- Alpine 3.23 (`v3.23`)
- Alpine 3.24 (`v3.24`)

Supported architectures are `x86_64`, `x86`, `aarch64`, `armv7`, `ppc64le`, `riscv64`, and `s390x`.

```sh
wget -O /etc/apk/keys/openrtmp-alpine.rsa.pub \
  https://packages.openrtmp.org/openrtmp-alpine.rsa.pub

echo "https://packages.openrtmp.org/alpine/v3.24/main" \
  >> /etc/apk/repositories

apk update
apk add librtmp2 librtmp2-dev
```

## Packages

APT creates `librtmp2` and `librtmp2-dev`.

Alpine creates `librtmp2`, `librtmp2-dev`, and `librtmp2-static`.
