### Installing
```bash
git clone git@github.com:tiannaru/dotfiles ~/.local/dotfiles
cd ~/.local/dotfiles
./scripts/deploy.sh
```
The `deploy.sh` script create symbolic link from repo to configuration files.
Backups are created in `~/.backup`.

### Usage
`tmux`, `vim`, `nvim` and other applications use this repository's config.
On install, a folder `~/.config/local_configs` is created, and it can be used to 
store private configuration, maybe under another repository.

### Extra
Keyboard layout: https://configure.ergodox-ez.com/ergodox-ez/layouts/APZKR/latest

# Future features
- handle ssh config
