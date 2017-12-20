#!/bin/sh -e

here=$(dirname $(readlink -f $0))

cd $here/pathogen
echo "Updating pathogen"
git pull

cd $here/bundle
for x in `ls` ; do
	echo "Updating $x"
	cd $x
	git pull
	cd ..
done
