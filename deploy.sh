#! /usr/bin/env bash

arg=$1

BACKUP_DIR="$HOME/.dotfiles_backup"
DOTFILES_URL="http://github.com/tiannaru/dotfiles.git"
DOTFILES_LOCATION="$HOME/.dotfiles"
# Ensure that we have the dotfiles repo cloned in the proper location
if ![test -d $HOME/.dotfiles]; then
  git clone DOTFILES_URL DOTFILES_LOCATION
fi
cd $DOTFILES_LOCATION

# Optionally, do a backup. This is nice if people don't want to commit.
# TODO also the a recovery script
# if [ $arg ] && [ $arg = "--backup" ]; then
#   echo -e "Also doing a backup inside $BACKUP_DIR\n"
#   mkdir $BACKUP_DIR
#   for dir in $(ls -d */); then
#     mv ~/$dir ~/.$BACKUP_DIR/$dir
#   done
# fi

# Instead of mucking around with the gitconfig file, I'd rather have it source
# a gitconfig file I have in git, and let the default ~/.gitconfig file loose
if grep -q "extra.gitconfig" ~/.gitconfig; then
  echo ".gitconfig properly configured already...weird"
else
  cat >> ~/.gitconfig <<- EOM
  [include]
  path = ~/.config/extra.gitconfig
  EOM
fi

stow */
