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
    functions -q gconfig; or exit 1
    functions fish_prompt | string match -q "*fish_git_prompt*"; or exit 1
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
# Exercise Fish's native Git prompt in a disposable repository.
export DOTFILES_TEST_REPO="$workspace/repo"
git init -q -b main "$DOTFILES_TEST_REPO"
printf 'initial\n' > "$DOTFILES_TEST_REPO/tracked"
git -C "$DOTFILES_TEST_REPO" add tracked
git -C "$DOTFILES_TEST_REPO" -c user.name=Test -c user.email=test@example.invalid commit -qm initial
check_git_prompt() {
    TERM=xterm-256color fish --no-config -c '
        source "$DOTFILES_FISH_CONFIG"
        cd "$DOTFILES_TEST_REPO"
        set -l raw (fish_git_prompt)
        string match -qr "\\e\\[[0-9;]*m" -- "$raw"; or exit 1
        set -l actual (string replace -ar "\\e\\[[0-9;]*m" "" -- "$raw")
        test "$actual" = "$argv[1]"; or begin
            printf "Expected <%s>, got <%s>\n" "$argv[1]" "$actual" >&2
            exit 1
        end
    ' "$1"
}
check_git_prompt ' (main)'
printf 'modified\n' >> "$DOTFILES_TEST_REPO/tracked"
check_git_prompt ' (main|✚)'
git -C "$DOTFILES_TEST_REPO" add tracked
check_git_prompt ' (main|●)'
touch "$DOTFILES_TEST_REPO/new-file"
check_git_prompt ' (main|●…)'
fish --no-config -c '
    source "$DOTFILES_FISH_CONFIG"
    cd "$HOME"
    set -l git_prompt (fish_git_prompt)
    test -z "$git_prompt"; or exit 1
'
printf 'Fish tests passed.\n'
