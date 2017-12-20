#!/bin/sh -e

here=$(dirname $(readlink -f $0))

plugins="
https://github.com/w0rp/ale.git
https://github.com/maralla/completor.vim.git
https://github.com/majutsushi/tagbar
https://github.com/vim-airline/vim-airline
https://github.com/tpope/vim-fugitive.git
https://github.com/airblade/vim-gitgutter.git
"

echo "Setting up pathogen"
git clone https://github.com/tpope/vim-pathogen $here/pathogen
ln -s $here/pathogen/autoload $here/autoload

mkdir $here/bundle
cd $here/bundle
for p in $plugins; do
	echo Cloning $p
	git clone $p
done

ln -s $here/vimrc $HOME/.vimrc
ln -s $here $HOME/.vim
