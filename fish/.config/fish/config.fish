fish_vi_key_bindings

# Fish settings
if status is-interactive
    fish_config theme choose "Catppuccin Macchiato"
end

# disables the vi mode prompt
function fish_mode_prompt
end
function fish_prompt --description 'Write out the prompt'
    set -l last_status $status
    echo -e ''
    # PWD
    set_color $fish_color_cwd
    echo -n (prompt_pwd)
    set_color normal
    echo -n ' '
    if set -q VIRTUAL_ENV
        set_color $fish_color_escape
        echo -n \((basename $VIRTUAL_ENV)\)
        set_color normal
    end
    fish_git_prompt
    echo
    if not test $last_status -eq 0
        set_color $fish_color_error
    end
    echo -n '➤ '
    set_color normal
end


# Keep intentional settings in config, not persisted universal variables.
set -g fish_prompt_pwd_dir_length 100
# Native Fish Git prompt: branch and change markers, with colors and symbols.
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showcolorhints 1
set -g __fish_git_prompt_use_informative_chars 1
set -gx VIRTUAL_ENV_DISABLE_PROMPT yes
set -gx PNPM_HOME "$HOME/.local/share/pnpm"

# General settings. --path avoids universal state and duplicate PATH entries.
fish_add_path --path "$HOME/.local/bin" "$HOME/.cargo/bin" \
    "$HOME/.opencode/bin" "$HOME/.bun/bin" "$PNPM_HOME"
set -gx EDITOR nvim

# Arch's mise package normally activates Fish through vendor_conf.d.
# Provide a fallback without registering the hooks twice or ignoring an opt-out.
if status is-interactive; and type -q mise
    if not functions -q __mise_env_eval
        if not set -q MISE_FISH_AUTO_ACTIVATE; or test "$MISE_FISH_AUTO_ACTIVATE" != 0
            mise activate fish | source
        end
    end
end


# open stuff in text editor
alias n "nvim"
alias rn "uv run nvim"
alias nconfig "nvim $HOME/.config/nvim/init.lua"
alias nlconfig "nvim $HOME/.config/local_configs/nvim.lua"
alias fconfig "nvim $HOME/.config/fish/config.fish"
alias gconfig "nvim $HOME/.config/ghostty/config"
alias gitconfig "nvim $HOME/.config/git/config"
alias glconfig "nvim $HOME/.config/git/local"

# misc stuff
alias b "bat"
alias rsource "source $HOME/.config/fish/config.fish"
alias rpython 'uv run --with rich python -i -c "from rich import inspect; from rich import pretty; pretty.install()"'

# kubectl
alias k kubectl

# git
alias g git
alias gs "git status"
alias ga "git add ."
alias gc "git commit -m"
alias gcl "git clone"
alias gco "git checkout"
alias ge "git clean -fd"
alias gd "git diff"
alias gac "git add . && git commit -m"
alias gu "git pull"
alias gpom "git pull origin master"
alias gp "git push"
alias gr "git reset HEAD --hard"
alias glo "git log"
alias gl "git lg"
alias gl2 "git lg2"
alias gw "git worktree"
# sometimes helps when git worktree is not updating
alias gsf "git fetch origin 'refs/heads/*:refs/heads/*'"
alias lg 'lazygit'

# eza aliases
alias e "eza"
alias ea "eza -a"
alias el "eza -l"
alias ela "eza -la"
alias et "eza -aT --git-ignore -I '.git|.venv|node_modules|.solid|__pycache__'"

# misc
alias stats "echo $status"
alias rmf "rm -rf"
# Keep the normal permission checks when launching Claude.
alias c "claude"

# abbreviaations
abbr ur "uv run"

# functions
## for neovim

# Opens neovim on the last file that was edited
function no
  set last_file (
      nvim --headless -u NONE \
          +'lua io.write(vim.v.oldfiles[1] or "")' +q 2>/dev/null
  )

  if test -n "$last_file"; and test -f "$last_file"
      nvim $last_file $argv
  else
      nvim $argv
  end
end


## for git
function gacp
    # git add commit push
    set message $argv[1]
    git add .; and git commit -m "$message"; and git push
end

# misc
function mkcd
    set folder $argv[1]
    set args $argv[2..]
    mkdir $args $folder
    cd $folder
end

# also load custom configs
if test -f ~/.config/local_configs/config.fish
    source ~/.config/local_configs/config.fish
end

# lol, straight from the examples page
function last_history_item
  echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item
