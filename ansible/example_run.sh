/bin/bash

ansible localhost -m include_role -a name=dotfiles --extra-vars "user=example github_email=example@example.com github_name=example" --ask-become-pass
