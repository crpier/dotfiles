#! /bin/bash

REPO_PATH=$HOME/.local/dotfiles
BACKUP_DIR=$HOME/.backup

# This is a terrible way to do this
sudo=$1

backup_and_link () {
    src=$1
    target=$2

    # If the config file is actually a path, backup the source
    target_path=$(realpath $target)
    mkdir -p $(dirname $BACKUP_DIR$target)
    # There is not "/" between the 2 vars because $target is an absolute path
    cp -r $target_path $BACKUP_DIR$target
    if [ -z $sudo ]; then
        rm -rf $target
    else
        sudo rm -rf $target
    fi

    # Misc files
    if [ -z $sudo ]; then
        ln -sf $src $target
    else
        sudo ln -sf $src $target
    fi
}

mkdir -p $BACKUP_DIR

# Individual files
backup_and_link $REPO_PATH/tmux.conf $HOME/.tmux.conf
backup_and_link $REPO_PATH/config/nvim/init.vim $HOME/.vimrc

# Make sure .gitconfig sources extra.gitconfig
./scripts/setup_gitconfig.sh

# The config folder can be iterated on
for i in $(ls $REPO_PATH/config); do
    backup_and_link $REPO_PATH/config/$i $HOME/.config/$i
done

# Make sure there are local config files
mkdir -p ~/.config/local_configs
touch $HOME/.config/local_configs/init.local.vim
touch $HOME/.config/local_configs/config.local.fish
touch $HOME/.config/local_configs/kitty.local.conf
touch $HOME/.config/local_configs/tmux.local.conf

