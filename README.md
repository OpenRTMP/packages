# OpenRTMP packages

This repository stores the OpenRTMP APT and Alpine APK repositories directly in the repository.

```text
.
├── dists/
├── pool/
│   └── main/
│       └── l/
│           └── librtmp2/
├── alpine/
│   └── v3.24/
│       └── main/
│           └── x86_64/
├── scripts/
└── .github/workflows/
```

`dists` and `pool` are the standard Debian APT directories. Alpine packages and indexes are stored below `alpine/<branch>/main/<architecture>/`. No additional `repo/` or `repository/` wrapper directory is used.

## Debian and Ubuntu

Supported distributions:

- Debian 12 (`bookworm`)
- Debian 13 (`trixie`)
- Ubuntu 22.04 LTS (`jammy`)
- Ubuntu 24.04 LTS (`noble`)
- Ubuntu 26.04 LTS (`resolute`)

Supported architectures:

- `amd64`
- `arm64`
- `armhf`
- `ppc64el`
- `riscv64`
- `s390x`
- `i386` for Debian where an official distribution image is available

The APT workflow creates:

- `librtmp2`: shared runtime library
- `librtmp2-dev`: C header, static library, and pkg-config metadata

## Alpine Linux

Supported Alpine branches:

- Alpine 3.21 (`v3.21`)
- Alpine 3.22 (`v3.22`)
- Alpine 3.23 (`v3.23`)
- Alpine 3.24 (`v3.24`)

Supported Alpine architectures:

- `x86_64`
- `x86`
- `aarch64`
- `armv7`
- `ppc64le`
- `riscv64`
- `s390x`

The Alpine workflow creates:

- `librtmp2`: shared runtime library
- `librtmp2-dev`: C header, shared-library link, and pkg-config metadata
- `librtmp2-static`: static library

Each `APKINDEX.tar.gz` and every `.apk` package is signed with the configured Alpine RSA key.

## Required repository secrets

APT repository:

- `APT_GPG_PRIVATE_KEY`
- `APT_GPG_PASSPHRASE`

Alpine repository:

- `ALPINE_RSA_PRIVATE_KEY`
- `ALPINE_RSA_PUBLIC_KEY`

Generate the Alpine key pair once with `abuild-keygen`, then store the complete private and public key contents in those secrets. The public keys are published as `openrtmp.gpg`, `openrtmp.asc`, and `openrtmp-alpine.rsa.pub`.

## Publishing a librtmp2 version

Run either workflow and enter a released version such as `0.6.0` or `v0.6.0`:

- **Build librtmp2 APT packages**
- **Build librtmp2 Alpine packages**

Both workflows also accept a `repository_dispatch` event of type `librtmp2-release` with this payload:

```json
{
  "event_type": "librtmp2-release",
  "client_payload": {
    "version": "0.6.0"
  }
}
```

## APT client configuration

Example for Debian 12:

```bash
curl -fsSL https://packages.openrtmp.org/openrtmp.gpg \
  | sudo tee /usr/share/keyrings/openrtmp.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/openrtmp.gpg] https://packages.openrtmp.org bookworm main" \
  | sudo tee /etc/apt/sources.list.d/openrtmp.list

sudo apt update
sudo apt install librtmp2 librtmp2-dev
```

## Alpine client configuration

Example for Alpine 3.24:

```sh
wget -O /etc/apk/keys/openrtmp-alpine.rsa.pub \
  https://packages.openrtmp.org/openrtmp-alpine.rsa.pub

echo "https://packages.openrtmp.org/alpine/v3.24/main" \
  >> /etc/apk/repositories

apk update
apk add librtmp2 librtmp2-dev
```
