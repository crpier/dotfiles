#!/bin/bash

# This is a low effort workaround for until there is a pacman package package for lunarvim (or at least a yay pagacke that works for me lmao)
LV_BRANCH=rolling bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/rolling/utils/installer/install.sh)
