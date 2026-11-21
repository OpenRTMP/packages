#!/usr/bin/env bash
# Publish a static site or one package ecosystem via SFTP, incrementally.
set -euo pipefail

mode="${1:?Expected site or a package repository name}"
case "$mode" in
  site|debian|ubuntu|alpine|rpm|arch|windows|homebrew) ;;
  *) echo "Unsupported publish target: $mode" >&2; exit 2 ;;
esac

: "${DEPLOY_USERNAME:?DEPLOY_USERNAME secret is required}"
: "${DEPLOY_PASSWORD:?DEPLOY_PASSWORD secret is required}"
: "${DEPLOY_REMOTE_PATH:?DEPLOY_REMOTE_PATH secret is required}"
: "${DEPLOY_KNOWN_HOSTS:?DEPLOY_KNOWN_HOSTS secret is required}"
DEPLOY_HOST="${DEPLOY_HOST:-vweb03.eu}"
DEPLOY_PORT="${DEPLOY_PORT:-22}"

# Validate the account-specific document root before interpolating it into lftp.
if [[ ! "$DEPLOY_REMOTE_PATH" =~ ^/?[A-Za-z0-9._/-]+$ ]] ||
   [[ "$DEPLOY_REMOTE_PATH" == "/" ]] ||
   [[ "$DEPLOY_REMOTE_PATH" =~ (^|/)\.\.(/|$) ]]; then
  echo "DEPLOY_REMOTE_PATH must be a specific safe directory (no spaces or '..')." >&2
  exit 2
fi
if [[ ! "$DEPLOY_HOST" =~ ^[A-Za-z0-9.-]+$ ]] ||
   [[ ! "$DEPLOY_PORT" =~ ^[0-9]{1,5}$ ]] ||
   [[ ! "$DEPLOY_USERNAME" =~ ^[A-Za-z0-9._@-]+$ ]]; then
  echo "Invalid SFTP host, port, or username." >&2
  exit 2
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"

# The password must never appear in a process argument or action log.
export LFTP_PASSWORD="$DEPLOY_PASSWORD"
unset DEPLOY_PASSWORD
remote="${DEPLOY_REMOTE_PATH%/}"
if [[ "$remote" != /* ]]; then
  remote="${remote#./}"
fi

connection="set cmd:fail-exit yes; set net:max-retries 3; set net:timeout 90; set xfer:disk-full-fatal yes; set xfer:use-temp-file yes; set mirror:overwrite yes; set sftp:connect-program \"ssh -a -x -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts\";"
remote_command() {
  lftp --env-password -u "$DEPLOY_USERNAME" -p "$DEPLOY_PORT" \
    "sftp://$DEPLOY_HOST" -e "$connection $1; bye"
}

if [[ "$mode" == "site" ]]; then
  python3 scripts/generate-package-site.py --output "$RUNNER_TEMP/package-site"
  echo "Publishing static website and indexes to $DEPLOY_HOST."
  remote_command "mkdir -p \"$remote\"; mirror -R --overwrite --no-perms --transfer-all --parallel=3 \"$RUNNER_TEMP/package-site\" \"$remote\""
  exit 0
fi

state_dir="$remote/.openrtmp-publish-state"
state_file="$state_dir/$mode.sha"
local_state="$RUNNER_TEMP/openrtmp-$mode.previous"
rm -f "$local_state"

# Missing state means this package folder has never been fully uploaded.
remote_command "get \"$state_file\" -o \"$local_state\"" >/dev/null 2>&1 || true
previous=""
if [[ -s "$local_state" ]]; then
  candidate="$(tr -d '\r\n' < "$local_state")"
  if [[ "$candidate" =~ ^[0-9a-f]{40}$ ]]; then
    previous="$candidate"
  else
    echo "Invalid remote $mode marker; refusing an unsafe fallback to full sync." >&2
    exit 1
  fi
fi

current="$(git rev-parse HEAD)"
if [[ -n "$previous" && "$previous" != "$current" ]]; then
  if ! git cat-file -e "$previous^{commit}" 2>/dev/null; then
    git fetch --quiet --no-tags --filter=blob:none origin "$previous" || true
  fi
  if ! git merge-base --is-ancestor "$previous" "$current" 2>/dev/null; then
    echo "Refusing to deploy $current: remote $mode already records $previous, which is not an ancestor." >&2
    echo "This is an out-of-order retry or a corrupt marker; refusing to downgrade published packages." >&2
    exit 1
  fi
fi

if [[ "${FORCE_FULL_SYNC:-false}" == "true" ]]; then
  echo "Full sync requested for $mode."
  previous=""
fi

if [[ -z "$previous" ]]; then
  # Partial checkout downloads only this matrix target's blobs, rather than
  # the complete multi-GB repository or all of its history.
  git sparse-checkout set "$mode" scripts
  echo "Initial full sync of $mode."
  remote_command "mkdir -p \"$remote\"; mirror -RL --overwrite --transfer-all --no-perms --parallel=2 \"$mode\" \"$remote/$mode\""
elif [[ "$previous" == "$current" ]]; then
  echo "$mode already at the current commit; no files to transfer."
else
  stage="$RUNNER_TEMP/openrtmp-upload"
  mkdir -p "$stage/$mode"
  changed_files="$RUNNER_TEMP/openrtmp-changed-files"
  git diff --no-renames --name-only --diff-filter=ACMRT -z \
    "$previous" HEAD -- "$mode" > "$changed_files"
  changed=0
  while IFS= read -r -d '' path; do
    case "$path" in "$mode/"*) ;; *) echo "Unsafe package path: $path" >&2; exit 1 ;; esac
    target="$stage/$path"
    mkdir -p "$(dirname "$target")"
    filemode="$(git ls-tree HEAD -- "$path" | awk '{print $1}')"
    if [[ "$filemode" == "120000" ]]; then
      # Symlinks are materialized as real downloadable files below.
      continue
    fi
    git show "HEAD:$path" > "$target"
    changed=$((changed + 1))
  done < "$changed_files"

  # SFTP hosts may not permit symlinks. Publish link aliases as real files
  # (e.g. pacman's openrtmp.db.sig -> openrtmp.db.tar.gz.sig). Re-publish
  # aliases whenever the target changes, even if the link blob did not.
  while IFS= read -r -d '' record; do
    metadata="${record%%$'\t'*}"
    path="${record#*$'\t'}"
    filemode="${metadata%% *}"
    [[ "$filemode" == "120000" ]] || continue
    link_target="$(git show "HEAD:$path")"
    if [[ -z "$link_target" || "$link_target" == */* || "$link_target" == "." || "$link_target" == ".." ]]; then
      echo "Unsupported package symlink target in $path" >&2
      exit 1
    fi
    target="$stage/$path"
    mkdir -p "$(dirname "$target")"
    git show "HEAD:${path%/*}/$link_target" > "$target"
    changed=$((changed + 1))
  done < <(git ls-tree -r -z HEAD -- "$mode")

  if (( changed > 0 )); then
    echo "Publishing $changed changed $mode files, not the full repository."
    # Delta files are always transferred even when size/mtime match.
    # Historical package files are retained rather than pruned.
    remote_command "mkdir -p \"$remote\"; mirror -R --overwrite --transfer-all --no-perms --parallel=2 \"$stage/$mode\" \"$remote/$mode\""
  else
    echo "No new or modified $mode packages."
  fi
fi

# Advance the state marker only after a complete successful upload.
printf '%s\n' "$current" > "$RUNNER_TEMP/openrtmp-current.sha"
remote_command "mkdir -p \"$state_dir\"; put \"$RUNNER_TEMP/openrtmp-current.sha\" -o \"$state_file\""
echo "$mode is synced to $current."
