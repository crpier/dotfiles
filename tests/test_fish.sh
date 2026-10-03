#!/usr/bin/env bash
# Test Fish configuration without modifying the real user's universal variables.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(mktemp -d)"
trap 'rm -rf -- "$workspace"' EXIT
export DOTFILES_FISH_CONFIG="$repo_dir/fish/.config/fish/config.fish"
export HOME="$workspace"
export XDG_CONFIG_HOME="$workspace/.config"
export XDG_DATA_HOME="$workspace/.local/share"
export XDG_STATE_HOME="$workspace/.local/state"
mkdir -p "$HOME/.local/bin" "$HOME/.cargo/bin"
fish --no-config -c '
    source "$DOTFILES_FISH_CONFIG"
    set -l first_path (string join : $PATH)
    source "$DOTFILES_FISH_CONFIG"
    test "$first_path" = (string join : $PATH); or exit 1
    set -q -U fish_prompt_pwd_dir_length; and exit 1
    functions -q ks; and exit 1
    functions -q kconfig; and exit 1
    functions -q ghosttyconfig; or exit 1
'
fish --no-config -c '
    source "$DOTFILES_FISH_CONFIG"
    set -g calls
    function git
        set -ga calls $argv[1]
        return 1
    end
    gacp test
    test (count $calls) = 1; and test "$calls[1]" = add; or exit 1
'
fish --no-config -c '
    source "$DOTFILES_FISH_CONFIG"
    set -g calls
    function git
        set -ga calls $argv[1]
        if test "$argv[1]" = commit
            return 1
        end
        return 0
    end
    gacp test
    test (count $calls) = 2; and test "$calls[2]" = commit; or exit 1
'
printf 'Fish tests passed.\n'
