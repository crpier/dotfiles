function fish_mode_prompt
end

set -U fish_prompt_pwd_dir_length 100
set -U VIRTUAL_ENV_DISABLE_PROMPT yas

alias P "cd ~/Projects"
alias n nvim
alias nconfig "lvim $HOME/.config/nvim/init.vim"
alias nlconfig "lvim $HOME/.config/local_configs/init.local.vim"
alias l lvim
alias lconfig "lvim $HOME/.config/lvim/lv-config.lua"
alias lvconfig "lvim $HOME/.local/share/lunarvim/lvim"
alias fconfig "lvim $HOME/.config/fish/config.fish"
alias flconfig "cd $HOME/.config/local_configs; and lvim $HOME/.config/local_configs/config.local.fish; and cd -"
alias tconfig "lvim $HOME/.tmux.conf"
alias vconfig "lvim $HOME/.vimrc"
alias tlconfig "lvim $HOME/.config/local_configs/tmux.local.conf"
alias rsource "source $HOME/.config/fish/config.fish"
alias k kubectl
alias g "git"
alias gs "git status"
alias ga "git add ."
alias gc "git commit -m"
alias gd "git diff"
alias gac "git add . && git commit -m"
alias gp "git push"
alias gr "git reset HEAD --hard"
alias glo "git log"
alias gl "git lg"
alias gl2 "git lg2"
alias gw "git worktree"
alias lg lazygit

set -gx PATH $PATH $HOME/go/bin

function gacp 
    set message $argv[1]
    git add .
    git commit -m "$message"
    git push
end

function take
    set folder $argv[1]
    set args $argv[2..]
    mkdir $args $folder
    cd $folder
end

function vcurl
    set url $argv[1]
    curl $url | vim -
end

function ncurl
    set url $argv[1]
    curl $url | lvim -
end

if test -f $HOME/.config/local_configs/config.local.fish
    source $HOME/.config/local_configs/config.local.fish
end
