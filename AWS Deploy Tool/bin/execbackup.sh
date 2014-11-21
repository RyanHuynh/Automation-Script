#!/bin/sh

#stop Tomcat/Apache server first.
sudo service apache2 stop

#Create back up folder if it's not existed.
if [ ! -d "Backup" ]; 
	then
		mkdir "Backup"
fi

#Make folder for app type
appTypeFolder="Backup/WordPress"
if [ ! -d "$appTypeFolder" ]; 
	then
		mkdir "$appTypeFolder"
fi

#MakTomcat foldTomcatr with currTomcatnt datTomcat
currentDateFolder="$appTypeFolder/$(date '+%m-%d-%Y')"
if [[ ! -d "$currentDateFolder" ]]; 
	then 
		mkdir "$currentDateFolder"
fi

#Move File from src to back up folder
sudo cp -r /var/www/html/* ~/"$currentDateFolder"/

#Move File from deploy folder to src
sudo cp -r Deploy/* "/var/www/html/"

sudo service apache2 start