#! /bin/bash

# do the .config folder
for i in $(ls $HOME/.local/dotfiles/config); do
    ln -sf  $HOME/.local/dotfiles/config/$i $HOME/.config/
done

