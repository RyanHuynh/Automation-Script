#!/bin/sh
#Create back up folder if it's not existed.
if [ ! -d "Deploy" ]; 
	then
		mkdir "Deploy"
fi
sudo rm -rf Deploy/*

exit