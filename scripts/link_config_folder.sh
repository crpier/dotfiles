#! /bin/bash

# do the .config folder
for i in $(ls config); do
    ln -sf  $(pwd)/config/$i $HOME/.config/
done


