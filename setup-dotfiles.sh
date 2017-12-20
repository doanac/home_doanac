#!/bin/bash

set -e

HERE=$(readlink -f $(dirname $0))

echo "Setting up .bashrc"
grep bashrc-doanac $HOME/.bashrc || printf "\n#ANDY CUSTOM\n. $CFGFILES/bashrc-doanac\n" >> $HOME/.bashrc

echo "Setting up gtk bookmarks"
[ -h $HOME/.gtk-bookmarks ] && rm $HOME/.gtk-bookmarks
ln -s $HERE/gtk-bookmarks $HOME/.gtk-bookmarks

[ -h $HOME/.ssh/config ] && rm $HOME/.ssh/config
ln -s $HERE/ssh_config $HOME/.ssh/config

echo "Setting up vim"
$HERE/vim/setup.sh

echo "Setting up i3"
[ -d $HOME/.config/i3 ] && rm -rf $HOME/.config/i3
ln -s $HERE/i3 $HOME/.config/i3

echo "Setting up pass"
git clone doanac@bettykrocks.com:/home/doanac/password-store $HOME/.password-store
