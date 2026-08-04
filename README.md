# OpenRTMP packages

This repository stores the OpenRTMP APT repository directly at repository root.

```text
.
├── dists/
├── pool/
│   └── main/
│       └── l/
│           └── librtmp2/
├── scripts/
└── .github/workflows/
```

`dists` is the standard Debian APT directory name. The workflow does not create an additional `repo/` or `repository/` directory.

## Supported distributions

- Debian 12 (`bookworm`)
- Debian 13 (`trixie`)
- Ubuntu 22.04 (`jammy`)
- Ubuntu 24.04 (`noble`)
- Architecture: `amd64`

## Packages

- `librtmp2`: shared runtime library
- `librtmp2-dev`: C header, static library, and pkg-config metadata

## Required repository secrets

Before running the workflow, add these GitHub Actions repository secrets:

- `APT_GPG_PRIVATE_KEY`: ASCII-armored private GPG key used to sign the repository
- `APT_GPG_PASSPHRASE`: passphrase of that key; use an empty secret only when the key has no passphrase

The workflow exports the corresponding public key to both `openrtmp.asc` and `openrtmp.gpg`.

## Publishing a librtmp2 version

Open **Actions → Build librtmp2 APT packages → Run workflow** and enter a released librtmp2 version such as `0.6.0` or `v0.6.0`.

The workflow:

1. checks out the matching `OpenRTMP/librtmp2` release tag;
2. builds separate packages in Debian and Ubuntu containers;
3. creates `librtmp2` and `librtmp2-dev` packages;
4. copies the `.deb` files into `pool/main/l/librtmp2/`;
5. regenerates `dists/<codename>/main/binary-amd64/Packages` and release metadata;
6. signs each distribution using the configured GPG key;
7. commits the updated APT repository to `main`.

It can also be triggered with a `repository_dispatch` event of type `librtmp2-release` and this payload:

```json
{
  "event_type": "librtmp2-release",
  "client_payload": {
    "version": "0.6.0"
  }
}
```

## Client configuration

After this repository is published through GitHub Pages or another static web server, users can install its signing key and source entry.

Example for Debian 12:

```bash
curl -fsSL https://packages.openrtmp.org/openrtmp.gpg \
  | sudo tee /usr/share/keyrings/openrtmp.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/openrtmp.gpg] https://packages.openrtmp.org bookworm main" \
  | sudo tee /etc/apt/sources.list.d/openrtmp.list

sudo apt update
sudo apt install librtmp2 librtmp2-dev
```
