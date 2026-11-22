# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed
- The package website has a new layout: a hero with a platform index, tabbed
  install snippets for every supported ecosystem (each with copy button), and
  a verification section that states the signing-key fingerprint. The generated
  directory indexes reuse the same theme, and the platform choice is remembered
  in `localStorage`. Both still build from plain static files, so the SFTP
  publisher is unchanged.
- APT setup uses the deb822 `.sources` format (default since Ubuntu 24.04)
  instead of one-line `.list` files, and the site serves the same
  `favicon.svg` as openrtmp.org.
- The website ships an `.htaccess` cache policy: HTML is revalidated on every
  request, CSS/JS/SVG may be reused for five minutes, and package files keep
  their default caching.

### Fixed
- Repository placeholder files (`.gitkeep`) are no longer published or linked:
  they are gone from the package trees, the directory indexes skip dotfiles,
  the SFTP mirror excludes them, and the site publish removes the copies that
  were already uploaded.
- The Alpine and RPM completeness checks require the runtime to share one
  revision with its siblings: runtime/development/static for Alpine and
  runtime/development for RPM. The development packages pin the runtime
  exactly, so a mixed `-rN`/`-N.<dist>` set is not installable even though it
  was reported as a complete release.
- The APT publish job publishes the architectures that built successfully when
  another matrix leg fails, so one emulated i386 DNS failure no longer
  discards every other package. A retry that adds no packages skips the
  metadata/signing/commit, and a failed Pages dispatch can be retried without
  rewriting metadata or advancing `main`.
- The package-version validation checks each APT publish step's own no-op gate
  instead of matching the condition anywhere in the workflow.
