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
set -gx PATH $PATH ~/.local/bin
set -gx EDITOR nvim
set -gx MANPAGER "/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma norelativenumber' -\""
set -gx PYTHONDONTWRITEBYTECODE 1

# bat settings
set -gx BAT_THEME "gruvbox-dark"
set -gx BAT_STYLE "numbers,changes"

# Aliases
# kittens
alias ks "kitty +kitten ssh"
# open stuff in text editor
alias n "nvim --startuptime ~/.local/share/nvim/startuptime.out"
alias nconfig "nvim $HOME/.config/nvim/init.lua"
alias nlconfig "nvim $HOME/.config/local_configs/init.local.vim"
alias fconfig "nvim $HOME/.config/fish/config.fish"
alias flconfig "nvim $HOME/.config/local_configs/config.fish"
alias kconfig "nvim $HOME/.config/kitty/kitty.conf"
alias klconfig "nvim $HOME/.config/kitty/kitty.conf"

# misc stuff
alias b "bat"
alias pipi "pip install"
alias fzfb "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
alias rsource "source $HOME/.config/fish/config.fish"
alias netlisten "netstat -anvp tcp | awk 'NR<3 || /LISTEN/'"


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
alias lg lazygit

# exa aliases
alias e "exa"
alias ea "exa -a"
alias el "exa -l"
alias ela "exa -la"
alias et "exa -aT -I '.git|.venv|node_modules|.solid|__pycache__'"

# misc
alias stats "echo $status"
alias rmf "rm -rf"

# functions
# for git
function gacp
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
