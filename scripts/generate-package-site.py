#!/usr/bin/env python3
"""Build a static package browser from Git metadata without downloading packages."""

from __future__ import annotations

import argparse
from collections import defaultdict
from html import escape
from pathlib import Path, PurePosixPath
import shutil
import subprocess
from urllib.parse import quote

PACKAGES = ("debian", "ubuntu", "alpine", "rpm", "arch", "windows", "homebrew")
PUBLIC_KEYS = ("openrtmp.asc", "openrtmp.gpg", "openrtmp-alpine.rsa.pub")


def git(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(repo), *args])


def package_tree(repo: Path) -> dict[str, dict[str, tuple[bool, int]]]:
    """Map each directory to children using tree metadata only (no blob fetch)."""
    directories: dict[str, dict[str, tuple[bool, int]]] = defaultdict(dict)
    data = git(repo, "ls-tree", "-r", "-z", "HEAD", "--", *PACKAGES)
    for record in filter(None, data.split(b"\0")):
        metadata, filename = record.split(b"\t", 1)
        mode, kind, _sha = metadata.decode("ascii").split()
        if kind != "blob":
            continue

        parts = PurePosixPath(filename.decode("utf-8")).parts
        for depth in range(1, len(parts)):
            parent = "/".join(parts[: depth - 1])
            directories[parent][parts[depth - 1]] = (True, 0)

        parent = "/".join(parts[:-1])
        directories[parent][parts[-1]] = (False, -2 if mode == "120000" else -1)

    return directories


def build_index(directory: str, entries: dict[str, tuple[bool, int]]) -> str:
    parts = directory.split("/")
    up = "../" * len(parts)
    breadcrumbs = ['<a href="' + up + '">Packages</a>']
    for index, part in enumerate(parts):
        distance = len(parts) - index - 1
        href = "../" * distance if distance else "./"
        breadcrumbs.append(f'<a href="{href}">{escape(part)}</a>')

    rows = []
    if directory:
        rows.append(
            '<tr data-file-row><td><a href="../" class="file-link">'
            '<span class="file-icon">↰</span> Parent directory</a></td>'
            '<td class="metadata">Directory</td></tr>'
        )

    for name, (is_directory, size) in sorted(
        entries.items(), key=lambda item: (not item[1][0], item[0].casefold())
    ):
        if name.startswith("."):
            continue  # Repository placeholders such as .gitkeep are not published.
        href = quote(name, safe="") + ("/" if is_directory else "")
        label = escape(name + ("/" if is_directory else ""))
        icon = "▣" if is_directory else "↧"
        kind = "Directory" if is_directory else ("Link" if size == -2 else "File")
        rows.append(
            f'<tr data-file-row><td><a class="file-link" href="{href}">'
            f'<span class="file-icon">{icon}</span>{label}</a></td>'
            f'<td class="metadata">{kind}</td></tr>'
        )

    title = escape(directory + "/")
    breadcrumb_markup = '<span class="separator">/</span>'.join(breadcrumbs)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="theme-color" content="#070b12">
  <title>{title} · OpenRTMP Packages</title>
  <meta name="description" content="Browse the official OpenRTMP signed package repository.">
  <link rel="icon" href="{up}assets/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="{up}assets/site.css">
  <script defer src="{up}assets/site.js"></script>
</head>
<body>
  <header class="site-header">
    <div class="container header-inner">
      <a href="{up}" class="brand" aria-label="OpenRTMP packages home">
        <svg class="brand-mark" viewBox="0 0 100 100" aria-hidden="true" focusable="false">
          <defs><linearGradient id="brand-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0" stop-color="#60a5fa"/><stop offset="100%" stop-color="#22d3ee"/>
          </linearGradient></defs>
          <circle cx="50" cy="50" r="38" fill="none" stroke="url(#brand-gradient)" stroke-width="10"
                  stroke-dasharray="205 35" stroke-dashoffset="-92" stroke-linecap="round"/>
          <polyline points="20,52 30,52 36,38 44,64 50,52 58,52" fill="none"
                    stroke="url(#brand-gradient)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M58 40 L78 52 L58 64 Z" fill="url(#brand-gradient)"/>
        </svg>
        <span>OpenRTMP<span class="brand-sub"> / packages</span></span>
      </a>
      <nav class="site-nav" aria-label="Main navigation">
        <a class="nav-link" href="{up}#install">Installation</a>
        <a class="nav-link" href="{up}#repositories">Repositories</a>
        <a class="nav-link" href="{up}#verify">Verify</a>
        <a class="nav-cta" href="https://github.com/OpenRTMP/packages" rel="noopener">GitHub ↗</a>
      </nav>
    </div>
  </header>
  <main class="container browse-page">
    <nav class="breadcrumb" aria-label="Breadcrumb">{breadcrumb_markup}</nav>
    <div class="heading-row">
      <div><div class="eyebrow">Package directory</div>
        <h1>{title}</h1>
        <p class="subtitle">Signed package files and repository metadata, served directly over HTTPS.</p>
      </div>
      <div class="count">{len(entries)} entries</div>
    </div>
    <div class="browser">
      <div class="browser-tools">
        <label for="file-search">Filter files</label>
        <input id="file-search" type="search" placeholder="Search this directory…" data-file-search>
      </div>
      <div class="table-scroll">
        <table>
          <thead><tr><th scope="col">Name</th><th scope="col">Type</th></tr></thead>
          <tbody data-file-rows>{''.join(rows)}</tbody>
        </table>
        <p class="no-results" data-no-results hidden>No files match your search.</p>
      </div>
    </div>
  </main>
  <footer class="site-footer container">
    <p>© OpenRTMP · MIT License</p>
    <div class="footer-links">
      <a href="https://openrtmp.org/" rel="noopener">openrtmp.org</a>
      <a href="https://github.com/OpenRTMP/packages" rel="noopener">Source</a>
      <a href="{up}#install">Installation</a>
    </div>
  </footer>
</body>
</html>
"""


def generate(repo: Path, output: Path) -> None:
    source = repo / "site"
    if not (source / "index.html").is_file():
        raise FileNotFoundError(f"Missing homepage: {source / 'index.html'}")

    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    shutil.copy2(source / "index.html", output / "index.html")
    shutil.copytree(source / "assets", output / "assets")

    for key in PUBLIC_KEYS:
        (output / key).write_bytes(git(repo, "show", f"HEAD:{key}"))

    tree = package_tree(repo)
    for directory, entries in sorted(tree.items()):
        if not directory:
            continue  # Homepage is handcrafted instead of a raw root listing.
        target = output / directory / "index.html"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(build_index(directory, entries), encoding="utf-8")

    print(f"Generated homepage, signing keys and {len(tree) - 1} directory indexes.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, default=Path("public"))
    options = parser.parse_args()
    generate(options.repo.resolve(), options.output.resolve())
