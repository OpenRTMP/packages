# OpenRTMP packages

This repository publishes native packages for Debian, Ubuntu, Alpine, Fedora,
Enterprise Linux, openSUSE, Arch Linux, Homebrew, and Windows.

## Package versioning

All packages use the **same upstream librtmp2 release** (`v0.17.1` is the
current example), while each target keeps its package manager's native
version format. Do not force Debian suffixes onto RPM, APK, Arch, Homebrew,
or Windows builds.

| Target | Example for librtmp2 v0.17.1 | New upstream release | Rebuild of the same release |
| --- | --- | --- | --- |
| Debian 13 (APT) | `0.17.1-1~trixie1` | Debian revision `1` | Increase `revision`, e.g. `-2~trixie1` |
| Ubuntu 26.04 (APT) | `0.17.1-1~resolute1` | Debian revision `1` | Increase `revision`, e.g. `-2~resolute1` |
| Ubuntu 26.10 (APT) | `0.17.1-1~stonking1` | Debian revision `1` | Increase `revision`, e.g. `-2~stonking1` |
| Fedora 44 (RPM) | `0.17.1-1.fc44` | RPM release `1` | Increase `revision`, e.g. `2.fc44` |
| Enterprise Linux 10 (RPM) | `0.17.1-1.el10` | RPM release `1` | Increase `revision`, e.g. `2.el10` |
| openSUSE Leap 16.0 (RPM) | `0.17.1-1.suse160` | RPM release `1` | Increase `revision`, e.g. `2.suse160` |
| Alpine (APK) | `0.17.1-r0` | Alpine `pkgrel=0` | Increase `pkgrel`, e.g. `-r1` |
| Arch Linux | `0.17.1-1` | Arch `pkgrel=1` | Increase `pkgrel`, e.g. `-2` |
| Homebrew | `0.17.1` | No formula revision | Use a formula `revision 1` only if a same-version formula rebuild is required |
| Windows (signed ZIP) | `librtmp2-0.17.1-windows-x86_64.zip` | Upstream version in filename | Publish a new release for changed binaries |

All example numbers are for the same upstream release, **not** a request
to rebuild or republish it. For release `v0.18.0`, the defaults reset to
APT `-1~<codename>1`, RPM `-1.<dist>`, Alpine `-r0`, Arch `-1`,
and Homebrew/Windows `0.18.0`.

Each native packaging workflow follows this default automatically on
`repository_dispatch` and offers a revision override when started
manually. The GitHub Release version remains the single source of truth.
Do not introduce an RPM/Debian epoch unless a real version-ordering
migration requires it. Existing published files are not renamed.

The Launchpad PPA in `OpenRTMP/librtmp2` independently uses a signed
Debian source-package version such as
`0.17.1-1~resolute15r1`: its run/attempt suffix makes re-uploads unique.
Its numeric value may differ from the separately hosted APT binary
repository; both still share the same upstream version.


## Debian repository

Supported releases:

- Debian 12 (`bookworm`)
- Debian 13 (`trixie`)

Supported architectures include `amd64`, `arm64`, `armhf`, `i386`, `ppc64el`,
`riscv64`, and `s390x` where the selected release provides an official
container image.

```bash
echo "deb [signed-by=/usr/share/keyrings/openrtmp.gpg] https://packages.openrtmp.org/debian bookworm main" \
  | sudo tee /etc/apt/sources.list.d/openrtmp.list
```

## Ubuntu repository

Supported releases:

- Ubuntu 22.04 LTS (`jammy`)
- Ubuntu 24.04 LTS (`noble`)
- Ubuntu 26.04 LTS (`resolute`)
- Ubuntu 26.10 (`stonking`)

Supported architectures are `amd64`, `arm64`, `armhf`, `ppc64el`, `riscv64`,
and `s390x`.

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

### APT package versioning

APT packages use the standard non-native Debian version format
`<upstream>-<revision>~<codename>1` (for example,
`0.17.1-1~resolute1` or `0.17.1-1~stonking1`).
The upstream version is taken from the librtmp2 release tag, and the
Debian packaging revision defaults to `1` again for every new
upstream release (including patch releases).

Previously published packages named `<upstream>-1+<codename>1` are
retained in the APT pools and metadata for compatibility. The new
format is used starting with newly published versions; republishing
an *identical* already published upstream version with the new format
would require increasing the packaging revision to avoid a downgrade.

## Alpine repository

Supported branches:

- Alpine 3.21 (`v3.21`)
- Alpine 3.22 (`v3.22`)
- Alpine 3.23 (`v3.23`)
- Alpine 3.24 (`v3.24`)
- Alpine Edge (`edge`)

Supported architectures are `x86_64`, `x86`, `aarch64`, `armv7`, `ppc64le`,
`riscv64`, and `s390x`.

```sh
wget -O /etc/apk/keys/openrtmp-alpine.rsa.pub \
  https://packages.openrtmp.org/openrtmp-alpine.rsa.pub

echo "https://packages.openrtmp.org/alpine/v3.24/main" \
  >> /etc/apk/repositories

apk update
apk add librtmp2 librtmp2-dev
```

## Fedora / DNF repository

Fedora 44 packages are built for `x86_64`, `aarch64`, `ppc64le`, and `s390x`.
Packages and repository metadata are signed with the OpenRTMP GPG key.

```bash
sudo tee /etc/yum.repos.d/openrtmp.repo >/dev/null <<'EOF'
[openrtmp]
name=OpenRTMP
baseurl=https://packages.openrtmp.org/rpm/fedora/44/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.openrtmp.org/openrtmp.asc
EOF

sudo dnf install librtmp2 librtmp2-devel
```

## Enterprise Linux / DNF repository

Enterprise Linux 9 and 10 packages are intended for RHEL-compatible systems
including RHEL, Rocky Linux, and AlmaLinux. Supported architectures are
`x86_64`, `aarch64`, `ppc64le`, and `s390x`.

```bash
sudo tee /etc/yum.repos.d/openrtmp.repo >/dev/null <<'EOF'
[openrtmp]
name=OpenRTMP
baseurl=https://packages.openrtmp.org/rpm/el/$releasever/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.openrtmp.org/openrtmp.asc
EOF

sudo dnf install librtmp2 librtmp2-devel
```

## openSUSE / Zypper repository

openSUSE Leap 16.0 packages are built for `x86_64`, `aarch64`, `ppc64le`, and
`s390x`.

```bash
sudo rpm --import https://packages.openrtmp.org/openrtmp.asc
sudo zypper addrepo --refresh \
  "https://packages.openrtmp.org/rpm/opensuse/16.0/$(uname -m)" openrtmp
sudo zypper refresh
sudo zypper install librtmp2 librtmp2-devel
```

## Arch Linux repository

The Arch Linux repository targets the official `x86_64` architecture. Packages
and repository databases are signed with the OpenRTMP GPG key.

```bash
curl -fsSL https://packages.openrtmp.org/openrtmp.asc -o /tmp/openrtmp.asc
key="$(gpg --show-keys --with-colons /tmp/openrtmp.asc | awk -F: '$1 == "fpr" { print $10; exit }')"
sudo pacman-key --add /tmp/openrtmp.asc
sudo pacman-key --lsign-key "$key"

sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[openrtmp]
SigLevel = Required DatabaseRequired
Server = https://packages.openrtmp.org/arch/$arch
EOF

sudo pacman -Syu librtmp2
```

## Homebrew

The Homebrew formula lives in its own tap,
[OpenRTMP/homebrew-tap](https://github.com/OpenRTMP/homebrew-tap), so
`brew` only clones that small repository instead of this one:

```bash
brew install openrtmp/tap/librtmp2
```

Homebrew 6.0+ requires third-party taps to be trusted before their
formulae are loaded ([Tap Trust](https://docs.brew.sh/Tap-Trust)).
Installing the fully qualified formula name
(`brew install openrtmp/tap/librtmp2`) trusts just that formula
automatically. To trust the whole tap up front instead, run
`brew trust openrtmp/tap`.

If you previously tapped this repository (`openrtmp/packages`), move to
the new tap. `brew update` migrates an installed librtmp2 on its own only
when `openrtmp/tap` is already trusted; otherwise it prints a notice and
leaves librtmp2 where it is. Either way, these steps move it and remove
the old, much larger tap:

```bash
brew uninstall librtmp2
brew untap openrtmp/packages
brew install openrtmp/tap/librtmp2
```

The formula is updated automatically when a new librtmp2 release is published.
On macOS Sequoia, Tahoe, and Golden Gate (arm64) - plus Sequoia and Tahoe
on Intel, where GitHub still offers an Intel runner - `brew install`
fetches a precompiled bottle instead of building from source; other
platforms, including macOS Sonoma (whose GitHub Actions runner is
deprecated), build librtmp2 locally.

## Windows

Signed Windows ZIPs are built for both `x86_64` and `arm64` for every
librtmp2 release with native Windows support (releases up to v0.11.0 do not
build on Windows and have no Windows packages). Each architecture is built,
tested (including RTMP and RTMPS loopback tests) and checked on a native
runner of that architecture before it is published.

Each ZIP contains `bin\librtmp2.dll`, the import library
`lib\librtmp2.dll.lib`, the static library `lib\librtmp2.lib`, the C header
`include\librtmp2\librtmp2.h`, README, the librtmp2 license, and the OpenSSL
license notice. OpenSSL is linked statically, so the DLL needs only Windows
system DLLs plus the Microsoft Visual C++ Redistributable (2015-2022) that
every Rust/MSVC DLL uses. Each archive has a SHA-256 checksum and an OpenPGP
signature.

The verification example below requires GnuPG (`gpg`) to be installed. The
trusted OpenRTMP package-signing key fingerprint is
`615A20712AA690E917D6DCEF75E87340DA09771D`.

PowerShell example:

```powershell
$version = (Invoke-RestMethod https://api.github.com/repos/OpenRTMP/librtmp2/releases/latest).tag_name.TrimStart('v')
$arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) { "arm64" } else { "x86_64" }
$base = "https://packages.openrtmp.org/windows/$arch/$version"
$file = "librtmp2-$version-windows-$arch.zip"
$keyFile = "openrtmp.asc"
$trustedFingerprint = "615A20712AA690E917D6DCEF75E87340DA09771D"

Invoke-WebRequest "$base/$file" -OutFile $file
Invoke-WebRequest "$base/$file.sha256" -OutFile "$file.sha256"
Invoke-WebRequest "$base/$file.asc" -OutFile "$file.asc"
Invoke-WebRequest "https://packages.openrtmp.org/openrtmp.asc" -OutFile $keyFile

$expectedHash = ((Get-Content "$file.sha256" -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
$actualHash = (Get-FileHash -Algorithm SHA256 $file).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) {
    throw "SHA-256 checksum verification failed."
}

$keyInfo = & gpg --batch --with-colons --show-keys $keyFile
$fingerprintLine = $keyInfo | Where-Object { $_ -like 'fpr:*' } | Select-Object -First 1
$fingerprint = ($fingerprintLine -split ':')[9]
if ($fingerprint -ne $trustedFingerprint) {
    throw "OpenRTMP signing key fingerprint verification failed."
}

& gpg --batch --import $keyFile
if ($LASTEXITCODE -ne 0) { throw "Failed to import the OpenRTMP signing key." }
& gpg --batch --verify "$file.asc" $file
if ($LASTEXITCODE -ne 0) { throw "OpenPGP signature verification failed." }

Expand-Archive $file -DestinationPath .
```

## Packages

- APT: `librtmp2`, `librtmp2-dev`
- Alpine: `librtmp2`, `librtmp2-dev`, `librtmp2-static`
- RPM/DNF/Zypper: `librtmp2`, `librtmp2-devel`
- Arch Linux: `librtmp2`
- Homebrew: `librtmp2`
- Windows: `x86_64` and `arm64` ZIPs (librtmp2 releases with native Windows support)
