#!/bin/sh

#stop Tomcat/Apache server first.
sudo service <service-type> stop

#Create back up folder if it's not existed.
if [ ! -d "Backup" ]; 
	then
		mkdir "Backup"
fi

#Make folder for app type
appTypeFolder="Backup/<app-type>"
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
sudo cp -r <target-deploy>* ~/"$currentDateFolder"/

#Move File from deploy folder to src
sudo cp -r Deploy/* "<target-deploy>"

sudo service <service-type> start