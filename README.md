### Description
These are my dotfiles. I am using `stow` to manage them, so you could call them `stowfiles` lmao.

Much inspiration from https://github.com/ChristianChiarulli/Machfiles.

### Installing
```bash
git clone git@github.com:tiannaru/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./deploy.sh
```
The deploy script just does `stow */` and links my .gitconfig to your .gitconfig, so that you can run `git config --global` to you heart's content. Honestly, I'd rather move it to an Ansible role, but maybe later.

### Structure
There are 2 important branches: `main` and `very_fast`.
On main I will try to be tidy and only add meaningful self-contained pull requests, so the history looks good as well. On fast I just push whatever crazy idea I have. Not stable, but cutting edge. Feel free to open issues for any of these 2 branches.

### Usage
`tmux`, `vim`, `nvim`, `i3` and other applications use this repository's config.

This is also nicely extensible. Many applications source config files from `~/.config/local_configs/`, so you can put more source controlled stuff next to you source controlled stuff. 
For example, you can fork this public repo, on both your work and personal laptops, and then extend it with private dotfiles repo. All that these other repos need is to keep config files in the `~/.config/local_configs/` folder.
Atm these files are used in local_configs:
- config.local.fish
- init.local.vim
- kitty.local.conf
- tmux.local.conf

There is also a list of programs that these dotfiles serve in the `programs` dir.

### Extra
Also my keyboard layout: https://configure.ergodox-ez.com/ergodox-ez/layouts/APZKR/latest

### TODO
- fish plugins `fisher` and `fzf-fish` are saved as-is in the repo. That's probably not good.
- backup script in case you try this on a not fresh install of manjaro (or not on manjaro lol)
- copy goodies from .vimrc to init.vim
- switch to lunarvim instead of my init.vim
- create dwm mapping for brightness change (or switch to i3 maybe??)
