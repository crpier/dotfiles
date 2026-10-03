#!/usr/bin/env bash
# Clone missing repositories without updating or replacing existing checkouts.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
home_dir="$HOME"
manifest="$repo_dir/repos.tsv"
check_only=false
while (($#)); do
  case "$1" in
    --home) home_dir="${2:?Missing --home value}"; shift 2 ;;
    --manifest) manifest="${2:?Missing --manifest value}"; shift 2 ;;
    --check) check_only=true; shift ;;
    *) printf 'Unknown repository option: %s\n' "$1" >&2; exit 1 ;;
  esac
done
home_dir="$(cd -- "$home_dir" && pwd -P)"
command -v git >/dev/null || { printf 'Error: git is required to clone repositories.\n' >&2; exit 1; }

# Normalize GitHub SSH/HTTPS spellings without changing other hosts' URLs.
normalize_url() {
  local url="${1%.git}"
  case "$url" in
    git@github.com:*) printf 'github:%s' "${url#git@github.com:}" ;;
    https://github.com/*) printf 'github:%s' "${url#https://github.com/}" ;;
    ssh://git@github.com/*) printf 'github:%s' "${url#ssh://git@github.com/}" ;;
    *) printf '%s' "$url" ;;
  esac
}

urls=()
targets=()
while IFS=$'\t' read -r url relative extra || [[ -n "$url" ]]; do
  [[ -z "$url" || "$url" == \#* ]] && continue
  if [[ -z "$relative" || -n "$extra" || "$relative" == /* || "$relative" == */ || "$relative" == *//* || "/$relative/" == */../* || "/$relative/" == */./* ]]; then
    printf 'Error: invalid repository mapping: %s\n' "$relative" >&2
    exit 1
  fi
  target="$home_dir/$relative"
  parent="$(dirname -- "$target")"
  while [[ "$parent" != "$home_dir" ]]; do
    if [[ -L "$parent" || (-e "$parent" && ! -d "$parent") ]]; then
      printf 'Error: unsafe repository parent: %s\n' "$parent" >&2
      exit 1
    fi
    parent="$(dirname -- "$parent")"
  done
  for previous in "${targets[@]}"; do
    if [[ "$target/" == "$previous/"* || "$previous/" == "$target/"* ]]; then
      printf 'Error: duplicate or overlapping repository destination: %s\n' "$target" >&2
      exit 1
    fi
  done
  if [[ -e "$target" || -L "$target" ]]; then
    checkout_root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)"
    origin="$(git -C "$target" remote get-url origin 2>/dev/null || true)"
    if [[ -L "$target" || "$checkout_root" != "$target" || -z "$origin" || "$(normalize_url "$origin")" != "$(normalize_url "$url")" ]]; then
      printf 'Error: %s is not the expected repository. Back it up manually before cloning.\n' "$target" >&2
      exit 1
    fi
  fi
  urls+=("$url")
  targets+=("$target")
done < "$manifest"

# All destinations have been checked before any network or filesystem changes.
$check_only && exit 0
staging=""
trap 'if [[ -n "$staging" ]]; then rm -rf -- "$staging"; fi' EXIT
for index in "${!targets[@]}"; do
  target="${targets[$index]}"
  if [[ -e "$target" ]]; then
    printf 'REPO OK %s (no pull or reset)\n' "$target"
    continue
  fi
  mkdir -p -- "$(dirname -- "$target")"
  staging="$(mktemp -d "$(dirname -- "$target")/.dotfiles-clone.XXXXXXXX")"
  printf 'CLONE %s -> %s\n' "${urls[$index]}" "$target"
  git clone -- "${urls[$index]}" "$staging/checkout"
  # Publish only a complete clone; a failed authentication leaves no partial target.
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Error: destination appeared while cloning: %s\n' "$target" >&2
    exit 1
  fi
  mv -T -- "$staging/checkout" "$target"
  rmdir -- "$staging"
  staging=""
done
