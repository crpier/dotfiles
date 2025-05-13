# Fish settings
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
    __terlar_git_prompt
    echo
    if not test $last_status -eq 0
        set_color $fish_color_error
    end
    echo -n '➤ '
    set_color normal
end


set -U fish_prompt_pwd_dir_length 100
set -U VIRTUAL_ENV_DISABLE_PROMPT yes

# General settings
set -gx PATH ~/.local/bin ~/.cargo/bin $PATH
set -gx EDITOR nvim
set -gx PYTHONPATH .

# Aliases
# kittens
alias ks "kitty +kitten ssh"
alias icat "kitty +kitten icat"

# open stuff in text editor
alias n "nvim"
alias nconfig "nvim $HOME/.config/nvim/init.lua"
alias nlconfig "nvim $HOME/.config/local_configs/nvim.lua"
alias fconfig "nvim $HOME/.config/fish/config.fish"
alias flconfig "nvim $HOME/.config/local_configs/config.fish"
alias kconfig "nvim $HOME/.config/kitty/kitty.conf"
alias klconfig "nvim $HOME/.config/local_configs/kitty.conf"
alias gconfig "nvim $HOME/.gitconfig"
alias glconfig "nvim $HOME/.config/extra.gitconfig"

# misc stuff
alias b "bat"
alias pipi "pip install"
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

# functions
## for git
function gacp
    # git add commit push
    set message $argv[1]
    git add .
    git commit -m "$message"
    git push
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
