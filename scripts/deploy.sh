#! /bin/bash

REPO_PATH=$HOME/.local/dotfiles
BACKUP_DIR=$HOME/.backup

backup_and_link () {
    src=$1
    target=$2

    # If the config file is actually a path, backup the source
    target_path=$(realpath $target)
    mkdir -p $(dirname $BACKUP_DIR$target)
    # There is not "/" between the 2 vars because $target is an absolute path
    cp -r $target_path $BACKUP_DIR$target
    rm -rf $target

    ln -sf $src $target
}

mkdir -p $BACKUP_DIR

# The .kde4 directory can be linked directly
backup_and_link $REPO_PATH/kde4 $HOME/.kde4

# Individual files
backup_and_link $REPO_PATH/tmux.conf $HOME/.tmux.conf
backup_and_link $REPO_PATH/config/nvim/init.vim $HOME/.vimrc

# Make sure .gitconfig sources extra.gitconfig
./scripts/setup_gitconfig.sh

# The config folder can be iterated on
for i in $(ls $REPO_PATH/config); do
    backup_and_link $REPO_PATH/config/$i $HOME/.config/$i
done

# TODO this should happen in the utils repo 
# Make sure there are local config files
mkdir -p ~/.config/local_configs
touch $HOME/.config/local_configs/init.local.vim
touch $HOME/.config/local_configs/config.local.fish
touch $HOME/.config/local_configs/kitty.local.conf
touch $HOME/.config/local_configs/tmux.conf

