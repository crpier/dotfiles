### Description
These are my dotfiles. I am using `stow` to manage them, so you could call them `stowfiles` lmao.

Much inspiration from https://github.com/ChristianChiarulli/Machfiles.

### Installing
After you just installed your OS, you need a few things:
- update your system
- create ssh key and add it to github
- install git and ansible if they don't exist

### Post installation
You'll need to do a few more things to seal the deal:
- open `lvim` and run a `:PackerInstall` and a `:PackerCompile`


```bash
git clone git@github.com:tiannaru/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./deploy.sh
```
The deploy script just does `stow */` and the `extra.gitconfig` to your .gitconfig, so that you can run `git config --global` safely.

### Usage
`tmux`, `vim`, `nvim` and other applications use this repository's config.

This is also nicely extensible. Many dotfiles here source other files from `~/.config/local_configs/`, so you can put more source controlled stuff next to you source controlled stuff. 
For example, you can fork this public repo, on both your work and personal laptops, and then extend it with private dotfiles repos. All that these other repos need is to keep config files in the `~/.config/local_configs/` folder.
ATM these files are used in local_configs:
- ~/.config/local_configs/config.fish
- ~/.config/local_configs/init.vim (for nvim)
- ~/.config/local_configs/kitty.local.conf (TODO rename this)
- ~/.config/local_configs/tmux.local.conf (TODO rename this)

### Extra
Also my keyboards' layouts: 
- Ergodox EZ: https://configure.ergodox-ez.com/ergodox-ez/layouts/APZKR/latest
- Dactyl Manuform 4x6: 
- Drop Preonic: 

### TODO
- gitconfig management: link the .extra.gitconfig file and also optionally set up user and email in gitconfig
- do the vagrant thingie
- spelling:
  - add the /home/cris/.config/lvim/spell/en.utf-8.add and track it in repo
- add config.lua for lvim to `local_configs`
- either remove ranger config or add it to ansible role
