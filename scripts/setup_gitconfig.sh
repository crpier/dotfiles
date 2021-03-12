#! /bin/bash

if grep -q "extra.gitconfig" ~/.gitconfig; then
    echo ".gitconfig properly configured already...weird"
else
cat >> ~/.gitconfig <<- EOM
[include]
    path = ~/.config/extra.gitconfig
EOM
fi
