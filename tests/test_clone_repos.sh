#!/usr/bin/env bash
# Offline repository tests using a local Git remote and a temporary home.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(mktemp -d)"
trap 'rm -rf -- "$workspace"' EXIT
mkdir -p "$workspace/home"
git init -q "$workspace/remote"
printf 'example\n' > "$workspace/remote/init.lua"
git -C "$workspace/remote" add init.lua
git -C "$workspace/remote" -c user.name=Test -c user.email=test@example.com commit -qm initial
printf '%s\t.config/nvim\n' "$workspace/remote" > "$workspace/repos.tsv"
run_clone() {
  bash "$repo_dir/scripts/clone_repos.sh" --home "$workspace/home" --manifest "$workspace/repos.tsv" "$@"
}
run_clone --check
[[ ! -e "$workspace/home/.config" ]]
run_clone
[[ -d "$workspace/home/.config/nvim/.git" ]]
printf 'local edit\n' > "$workspace/home/.config/nvim/init.lua"
run_clone
[[ "$(< "$workspace/home/.config/nvim/init.lua")" == 'local edit' ]]
# A GitHub spelling must not be confused with a similarly named local remote.
printf 'https://github.com/%s.git\t.config/nvim\n' "$workspace/remote" > "$workspace/repos.tsv"
if run_clone --check; then echo 'Expected host distinction' >&2; exit 1; fi
# SSH and HTTPS spellings of the same GitHub repository are equivalent.
git -C "$workspace/home/.config/nvim" remote set-url origin git@github.com:crpier/nvim.git
printf 'https://github.com/crpier/nvim.git\t.config/nvim\n' > "$workspace/repos.tsv"
run_clone --check
for destination in '../escape' '.config/../escape' '.config//nvim' '.config/nvim/' '/absolute'; do
  printf '%s\t%s\n' "$workspace/remote" "$destination" > "$workspace/repos.tsv"
  if run_clone --check; then echo 'Expected path rejection' >&2; exit 1; fi
done
printf '%s\t.config/nvim\n' "$workspace/wrong-remote" > "$workspace/repos.tsv"
if run_clone --check; then echo 'Expected wrong-origin rejection' >&2; exit 1; fi
rm -rf "$workspace/home/.config/nvim"
mkdir "$workspace/home/.config/nvim"
printf 'keep\n' > "$workspace/home/.config/nvim/original"
if run_clone; then echo 'Expected existing-directory rejection' >&2; exit 1; fi
[[ -f "$workspace/home/.config/nvim/original" ]]
rm -rf "$workspace/home/.config/nvim"
if run_clone; then echo 'Expected clone failure' >&2; exit 1; fi
[[ ! -e "$workspace/home/.config/nvim" ]]
[[ -z "$(find "$workspace/home/.config" -name '.dotfiles-clone.*' -print)" ]]
for arguments in '--all --clone-repos' '--all --apply --dry-run --clone-repos'; do
  # Intentional word splitting to test each fixed argument sequence.
  if bash "$repo_dir/deploy.sh" --home "$workspace/home" $arguments; then
    echo 'Expected clone flag validation failure' >&2; exit 1
  fi
done
printf 'Repository tests passed.\n'
