function fish_mode_prompt
end

alias n nvim
alias nconfig "nvim ~/.config/nvim/init.vim"
alias nlconfig "nvim ~/.config/local_configs/init.local.vim"
alias vconfig "nvim ~/.vimrc"
alias fconfig "nvim ~/.config/fish/config.fish"
alias flconfig "nvim ~/.config/local_configs/config.local.fish"
alias rsource "source ~/.config/fish/config.fish"

alias g "git"
alias gs "git status"
alias ga "git add ."
alias gc "git commit -m"
alias gd "git diff"
alias gac "git add . && git commit -m"
alias gp "git push"
alias gr "git reset HEAD --hard"

set -gx PATH $PATH $HOME/Tools

if test -f $HOME/.config/local_configs/config.local.fish
    source $HOME/.config/local_configs/config.local.fish
end

