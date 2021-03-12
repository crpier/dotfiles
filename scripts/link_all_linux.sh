#! /bin/bash

# The .kde4 directory can be linked directly
ln -sf  $(pwd)/kde4 $HOME/.kde4

# The config folder's subfolders need to be linked individually
./scripts/link_config_folder.sh

# Individual files
ln -sf $(pwd)/tmux.conf $HOME/.tmux.conf

# Touch local rc files
touch $HOME/.config/nvim/init.local.vim
touch $HOME/.config/fish/config.local.fish
