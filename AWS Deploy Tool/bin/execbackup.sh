#!/bin/sh

#stop Tomcat/Apache server first.
sudo service tomcat7 stop

#Create back up folder if it's not existed.
if [ ! -d "Backup" ]; 
	then
		mkdir "Backup"
fi

#Make folder for app type
appTypeFolder="Backup/Java"
if [ ! -d "$appTypeFolder" ]; 
	then
		mkdir "$appTypeFolder"
fi

#MakTomcat foldTomcatr with currTomcatnt datTomcat
currentDateFolder="$appTypeFolder/11-27-2014"
if [[ ! -d "$currentDateFolder" ]]; 
	then 
		mkdir "$currentDateFolder"
fi

#Move File from src to back up folder
sudo cp -r /var/lib/tomcat7/webapps/* ~/"$currentDateFolder"/

#Move File from deploy folder to src
sudo cp -r Deploy/* "/var/lib/tomcat7/webapps/"

sudo service tomcat7 start