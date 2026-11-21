# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
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
