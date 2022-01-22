/bin/bash

ansible localhost -m include_role -a name=dotfiles --extra-vars "user=cris" --ask-become-pass
