#!/bin/bash

echo "1. Download update"
echo "2. Upload update"
echo "3. Reset current"

printf "> "

read -r menu1

if [ "$menu1" = "1" ]; then
	git pull origin master
	exit
fi

if [ "$menu1" = "2" ]; then
	git add .
	
	if git commit -a; then
		git push -u origin master
	fi

	exit
fi

if [ "$menu1" = "3" ]; then
	printf "Hard reset? (y/N): "

	read -r hard

	if [ "$hard" = "y" ]; then
		git reset --hard
	else
		git reset
	fi

	exit
fi

echo "Goodbye"

read -r -p "Press any key to continue . . . "
