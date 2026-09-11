# OpenRTMP packages

This repository publishes native packages for Debian, Ubuntu, Alpine, Fedora,
Enterprise Linux, openSUSE, Arch Linux, Homebrew, and Windows.

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

## Alpine repository

Supported branches:

- Alpine 3.21 (`v3.21`)
- Alpine 3.22 (`v3.22`)
- Alpine 3.23 (`v3.23`)
- Alpine 3.24 (`v3.24`)

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

The repository also acts as a Homebrew tap. Because the GitHub repository is
named `packages` rather than `homebrew-packages`, add it with its explicit
remote once:

```bash
brew tap openrtmp/packages https://github.com/OpenRTMP/packages
brew install openrtmp/packages/librtmp2
```

Run the `brew tap` command with the explicit URL first. `brew install
openrtmp/packages/librtmp2` on its own will try to auto-tap using
Homebrew's default naming convention (`homebrew-packages`), which doesn't
exist and fails to clone.

Homebrew 6.0+ requires third-party taps to be trusted before their
formulae are loaded ([Tap Trust](https://docs.brew.sh/Tap-Trust)), so
`brew tap` may print `Invalid formula` / `untrusted tap` warnings the
first time — this is expected. Installing the fully qualified formula
name (`brew install openrtmp/packages/librtmp2`) trusts just that
formula automatically. To trust the whole tap up front instead, run
`brew trust openrtmp/packages`.

The formula is updated automatically when a new librtmp2 release is published.

## Windows

Signed Windows packages are built for both `x86_64` and `arm64`. Each ZIP
contains the native DLL, import/static libraries, C header, README, librtmp2
license, and the OpenSSL license notice. OpenSSL is linked statically into both
builds. Each ZIP is accompanied by SHA-256 and OpenPGP signature files.

The verification example below requires GnuPG (`gpg`) to be installed. The
trusted OpenRTMP package-signing key fingerprint is
`615A20712AA690E917D6DCEF75E87340DA09771D`.

PowerShell example for the latest release:

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
- Windows: signed `x86_64` and `arm64` binary ZIPs
