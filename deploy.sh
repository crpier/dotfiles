#! /usr/bin/env bash

# Instead of mucking around with the gitconfig file, I'd rather have it source
# a gitconfig file I have in git, and let the default ~/.gitconfig file loose
# Altough, tbf, this piece would sit better in an ansible role (~˘▾˘)~
if grep -q "extra.gitconfig" ~/.gitconfig; then
    echo ".gitconfig properly configured already...weird"
else
cat >> ~/.gitconfig <<- EOM
[include]
    path = ~/.config/extra.gitconfig
EOM
fi

stow */
