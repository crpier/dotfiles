stow $(ls -d */ | grep -v ansible)
# Instead of mucking around with the gitconfig file, I'd rather have it source
# a gitconfig file I have in git, and let the default ~/.gitconfig file loose
if grep -q "extra.gitconfig" ~/.gitconfig; then
  echo ".gitconfig properly configured already. Noice 👍"
else
  cat >> ~/.gitconfig <<- EOM
  [include]
  path = ~/.config/extra.gitconfig
EOM
fi

