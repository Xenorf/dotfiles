#!/bin/sh
git clone --bare https://github.com/Xenorf/dotfiles.git $HOME/.dotfiles
# Define config alias locally since the dotfiles aren't installed on the system yet
function dotfiles {
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
# Create a directory to backup existing dotfiles
mkdir -p .dotfiles-backup
dotfiles checkout
if [ $? = 0 ]; then
  echo "Checked out dotfiles from git@github.com:Xenorf/dotfiles.git";
  else
    echo "Moving existing dotfiles to ~/.dotfiles-backup";
    dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi

# Checkout dotfiles from repo
dotfiles checkout
dotfiles config status.showUntrackedFiles no
dotfiles config core.excludesFile $HOME/.config/git/gitignore
