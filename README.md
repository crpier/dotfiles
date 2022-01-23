### Description
These are my dotfiles. I am using `stow` to manage them, so you could call them `stowfiles` lmao.

Much inspiration from https://github.com/ChristianChiarulli/Machfiles.

### Installing
After you just installed your OS, you need a few things:
- update your system
- create ssh key and add it to github
- install git and ansible if they don't exist
- if you want to install lunarvim, install it now using the `install_lunarvim.sh` script

### Post installation
You'll need to do a few more things to seal the deal:
- open `lvim` and run a `:PackerInstall` and a `:PackerCompile`

### Work in progress
This isn't in maintenance mode yet, but in development. As such, there are a few catches:
- can't install lunarvim from ansible yet, so there is a script `install_lunarvim.sh` that we use until we have a proper package for lunarvim that can be used to also install dependencies without any user involvement

### Known issues
- You might encounter something an with this is in it in `nvim` or `vim` (though not in `lvim`)
```
This extension doesn't exist or is not installed: fzf
```
Happens because the post-install hook for `telescope-fzf-native.nvim` didn't run. No idea why 😔
You can fix it by running `PlugInstall!` in vim/nvim to force the post-install hooks to run.

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
- ~/.config/local_configs/init.vim
- ~/.config/local_configs/.vimrc
- ~/.config/local_configs/kitty.conf
- ~/.config/local_configs/.tmux.conf

### Extra
Also my keyboards' layouts: 
- Ergodox EZ: https://configure.ergodox-ez.com/ergodox-ez/layouts/APZKR/latest
- Dactyl Manuform 4x6: https://github.com/tiannaru/qmk_firmware/tree/master/keyboards/handwired/dactyl_manuform/4x6/keymaps/based_vim
- Drop Preonic: https://github.com/tiannaru/qmk_firmware/tree/master/keyboards/preonic/keymaps/based_vim

### TODO
- either remove ranger config or add it to ansible role
- create tmux scripts based on templates (for example using the `repos_folder` to select repos)
- put all the config backups in one place
