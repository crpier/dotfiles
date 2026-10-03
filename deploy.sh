#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'Error: python3 is required.\n' >&2
  exit 1
fi
# Repository cloning is an explicit additional step, independent of symlink packages.
clone_repos=false
apply=false
preview=false
informational=false
home_dir="$HOME"
link_args=()
while (($#)); do
  case "$1" in
    --clone-repos) clone_repos=true; shift ;;
    --apply) apply=true; link_args+=("$1"); shift ;;
    --dry-run) preview=true; link_args+=("$1"); shift ;;
    --list|-h|--help) informational=true; link_args+=("$1"); shift ;;
    --home) home_dir="${2:?Missing --home value}"; link_args+=("$1" "$2"); shift 2 ;;
    --home=*) home_dir="${1#--home=}"; link_args+=("$1"); shift ;;
    *) link_args+=("$1"); shift ;;
  esac
done
if $informational; then
  printf 'Repository option: --clone-repos clones repos.tsv entries (requires --apply).\n'
fi
if $clone_repos; then
  if ! $apply || $preview || $informational; then
    printf 'Error: --clone-repos requires --apply and cannot be combined with --dry-run, --list, or --help.\n' >&2
    exit 1
  fi
  bash "$repo_dir/scripts/clone_repos.sh" --home "$home_dir" --check
fi
python3 "$repo_dir/scripts/link_dotfiles.py" "${link_args[@]}"
if $clone_repos; then
  bash "$repo_dir/scripts/clone_repos.sh" --home "$home_dir"
fi

