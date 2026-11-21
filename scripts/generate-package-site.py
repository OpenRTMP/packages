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


def human_size(size: int) -> str:
    value = float(size)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if value < 1024 or unit == "TiB":
            return f"{int(value)} {unit}" if unit == "B" else f"{value:.1f} {unit}"
        value /= 1024
    return str(size)


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
            '<td class="metadata">Directory</td><td class="metadata">—</td></tr>'
        )

    for name, (is_directory, size) in sorted(
        entries.items(), key=lambda item: (not item[1][0], item[0].casefold())
    ):
        href = quote(name, safe="") + ("/" if is_directory else "")
        label = escape(name + ("/" if is_directory else ""))
        icon = "▣" if is_directory else "↧"
        kind = "Directory" if is_directory else ("Link" if size == -2 else "File")
        display_size = "—"
        rows.append(
            f'<tr data-file-row><td><a class="file-link" href="{href}">'
            f'<span class="file-icon">{icon}</span>{label}</a></td>'
            f'<td class="metadata">{kind}</td>'
            f'<td class="metadata">{display_size}</td></tr>'
        )

    title = escape(directory + "/")
    breadcrumb_markup = '<span class="separator">/</span>'.join(breadcrumbs)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="theme-color" content="#0b1019">
  <title>{title} · OpenRTMP Packages</title>
  <meta name="description" content="Browse the official OpenRTMP signed package repository.">
  <link rel="icon" href="{up}assets/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="{up}assets/site.css">
  <script defer src="{up}assets/site.js"></script>
</head>
<body>
  <header class="topbar">
    <div class="container nav-inner">
      <a href="{up}" class="brand"><span class="brand-mark">OR</span>
        <span>OpenRTMP<span class="brand-muted"> / packages</span></span></a>
      <nav aria-label="Main navigation">
        <a href="{up}#install">Installation</a>
        <a href="{up}#browse">Repositories</a>
        <a href="https://github.com/OpenRTMP/packages" rel="noopener">GitHub ↗</a>
      </nav>
    </div>
  </header>
  <main class="container browse-page">
    <nav class="breadcrumb" aria-label="Breadcrumb">{breadcrumb_markup}</nav>
    <div class="heading-row">
      <div><div class="eyebrow">PACKAGE DIRECTORY</div>
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
          <thead><tr><th scope="col">Name</th><th scope="col">Type</th><th scope="col">Size</th></tr></thead>
          <tbody data-file-rows>{''.join(rows)}</tbody>
        </table>
        <p class="no-results" data-no-results hidden>No files match your search.</p>
      </div>
    </div>
  </main>
  <footer class="footer container"><span>© OpenRTMP · MIT License</span>
    <span><a href="https://openrtmp.org/">Project website</a> ·
    <a href="https://github.com/OpenRTMP/packages">Source repository</a></span>
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
