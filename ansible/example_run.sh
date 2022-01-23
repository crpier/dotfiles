/bin/bash

ansible localhost -m include_role -a name=dotfiles --extra-vars "user=cris github_email=tiannaru42@gmail.com github_name=tiannaru" --ask-become-pass
