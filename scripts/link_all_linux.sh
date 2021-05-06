#! /bin/bash

# The .kde4 directory can be linked directly
ln -sf  $(pwd)/kde4 $HOME/.kde4

# The config folder's subfolders need to be linked individually
./scripts/link_config_folder.sh

# Individual files
ln -sf $(pwd)/tmux.conf $HOME/.tmux.conf
ln -sf $(pwd)/config/nvim/init.vim $HOME/.vimrc

# Link misc folders
rm -rf $HOME/.local/share/konsole
ln -sf $(pwd)/misc/konsole/ $HOME/.local/share/

# Make sure .gitconfig sources extra.gitconfig
./scripts/setup_gitconfig.sh

# Make sure there are local config files
mkdir -p ~/.config/local_configs
touch $HOME/.config/local_configs/init.local.vim
touch $HOME/.config/local_configs/config.local.fish
touch $HOME/.config/local_configs/kitty.local.conf
touch $HOME/.config/local_configs/tmux.conf

