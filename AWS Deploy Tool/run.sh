#AWS DEPLOY TOOL 
#Created by Ryan Huynh
#Version 2.01

#!/bin/bash 
# Some ultilities variables
yellow='\e[1;33m'
lCyan='\e[1;36m'
noColor='\e[0m'
red='\e[0;31m'
green='\e[0;32m'

#Main functions for our script

#Function to check for credential. Crediential only need to enter one, unless you change to different region
function credentialCheck {
	while true; do
		echo -e "\nYou need to configure your AWS crediential first, configure your crediential now (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
		read userInput
		echo -e "${noColor}\c"
		if [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "y" ]]; then
			echo -e "${red}${bold}NOTE: ${noColor}${normal}For region, please specify the region in which your instance lives (e.g. us-west-1)\n"
			aws configure			
			break
		elif [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "n" ]]; then
			break
		fi
		echo -e "${red}$userInput is not a valid choice. ${noColor}"
	done
}

#Function for input instanceID
function inputInstanceID {
	instanceList=`aws ec2 describe-instances`
	instanceIDList=`echo "$instanceList" | grep '"InstanceId"' | grep -o i-[^\"]*`
	while true; do
		echo -e "\nChoose the instanceID of your instance ( ${green}-help${noColor} to display list of instances for this region ): ${green}\c"
		read instanceID
		echo -e "${noColor}\c"
		if [[ "$instanceID" == '-help' ]]; then		
			echo -e "\n${yellow}The current available instances in this region: "
			for i in $(echo $instanceIDList | tr " " "\n" ); do 
				listItem=`aws ec2 describe-instances --filters Name=instance-id,Values=$i | grep "Value" | grep -o ": \".*" | grep -o "[0-9a-zA-Z ]*" | tr -d '\n'`
				if [[ "$listItem" == '' ]]; then
					echo "Unknown Name: $i"
				else
					echo "$listItem: $i"
				fi
			done
			echo -e "${noColor}\c"
		elif [[ `echo "$instanceID" | grep ''` != `echo ''` ]] && [[ `echo "$instanceIDList" | grep "$instanceID"` ]]; then
			break
		else
			echo -e "${red}$instanceID is not a valid instance ID${noColor}"	
		fi	
	done
}

#function for capplication type. Application type choice will decide:
#      - Service your application need (e.g Apache server for WordPress, Tomcat7 for Tomcat, etc...)
#      - Backup folder's name for your application.
function appTypeChoice {
	while true; do
		echo -e "\nType of application ( ${green}Java${noColor} or ${green}WordPress${noColor} ): ${green}\c" 
		read appType
		echo -e "${noColor}\c"
		if [[ `echo "$appType" | tr -d ''` != `echo ''` ]] && [[ "$appType" == "Java" || "$appType" == "WordPress" ]] ; then
			break
		fi
		echo -e "${red}$appType is not a valid type.${noColor}"	
	done
}

#Function for target deployment path. Default path for each service is defined as:
#      - Tomcat: /var/lib/tomcat7/webapps/
#      - WordPress: /var/www/html/wp-content/
function targetDeploymentPath {
	targetPathModified=false
	while true; do
		echo -e "\nThe target deploy path on the server is \c"
		if [[ "$targetPathModified" == false ]]; then
			if [[ "$appType" == "Java" ]]; then
				targetPath="/var/lib/tomcat7/webapps/"
				serviceType="tomcat7"
			elif [[ "$appType" == "WordPress" ]]; then
				targetPath="/var/www/html/wp-content/"
				serviceType="apache2"
			fi
		fi
		echo -e "${yellow}\"$targetPath\"${noColor}. \c" 
		echo -e "Comfirm (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
		read folderComfirm
		echo -e "${noColor}\c"
		if [[ `echo "$folderComfirm" | tr [:upper:] [:lower:]` == "y" ]]; then
			break
		elif [[ `echo "$folderComfirm" | tr [:upper:] [:lower:]` == "n" ]]; then
			echo -e "\nNew target path: ${green}\c"
			read targetPath	
			targetPathModified=true	
			echo -e "${noColor}\c"
		else
			echo -e "${red}$folderComfirm is not a valid choice.${noColor}"
		fi
	done
}

#Function for db backup
function dbBackupFunct {
	dbConnectionChk=false
	while [[ "$dbConnectionChk" == false ]]; do
		echo -e "\nBack up database for this application ( ${green}Y${noColor}/${green}N${noColor} ): ${green}\c"
		read dbBackup
		echo -e "${noColor}\c"
		if [[ `echo "$dbBackup" | tr [:upper:] [:lower:]` == "y" ]]; then 
			while true; do
				echo -e "\nWhich type of your database ( type ${green}mySQL${noColor} or ${green}SQLserver${noColor} ): ${green}\c"
				read databaseType
				echo -e "${noColor}\c"
				if [[ "$databaseType" == "mySQL" ]]; then
					echo -e "\nEnter server name of your database: ${green}\c"
					read hostName
					echo -e "${noColor}"
					echo -e "Enter database name: ${green}\c"
					read dbName
					echo -e "${noColor}"
					echo -e "Enter username: ${green}\c"
					read dbuser
					echo -e "${noColor}"
					echo -e "Enter password: ${green}\c"
					read -s dbpass
					echo -e "${noColor}\n"
					echo -e "${yellow}Checking database connection.....\c"
					sqlcmd=`mysql -u $dbuser -p$dbpass -h $hostName -D $dbName -e "show databases"`	
					if [[ "$sqlcmd" != '' ]]; then
						echo -e "SUCCESS${noColor}"
						let dbConnectionChk=true								
					fi							
						echo -e "${noColor}\c"	
						break
				elif [[ "$databaseType" == "SQLserver" ]]; then
					echo -e "${yellow}SQLserver is not supported atm.${noColor}"
					#echo -e "\nEnter server name of your database: ${green}\c"
					#read hostName
					#echo -e "${noColor}"
					#echo -e "Enter database name: ${green}\c"
					#read dbName
					#echo -e "${noColor}"
					#echo -e "Enter username: ${green}\c"
					#read dbuser
					#echo -e "${noColor}"
					#echo -e "Enter password: ${green}\c"
					#read -s dbpass
					#echo -e "${noColor}\n"
					#echo -e "${yellow}Checking database connection.....\c"
					#sqlcmd=`sqlcmd -S $hostName -U $dbuser -P $dbpass -d $dbName -q "exit"`	
					#if [[ "$sqlcmd" != '' ]]; then
						#echo -e "SUCCESS${noColor}"
						#let dbConnectionChk=true								
					#fi							
						#echo -e "${noColor}"	
						#break
				else
					echo -e "${red}$databaseType is not a valid database type.${noColor}"
				fi
			done
			
		elif [[ `echo "$dbBackup" | tr [:upper:] [:lower:]` == "n" ]]; then 
			break
		else
			echo -e "${red}$dbBackup is not a valid option.${noColor}"
		fi
	done
}

#Read configuration from config files.
function runFromConfig {
	echo -e "\n${yellow}List of available config files:"
	listConfigFile=`ls Config/* | grep Config | grep -o "/[^.]*" | grep -o [^/]*`
	let count=0
	for i in $(echo $listConfigFile | tr " " "\n"); do
		let count+=1
		echo "$count. $i"
		configFileArray["$count"]="$i"
	done
	while true; do		
		echo -e "${noColor}"
		echo -e "Which config file you want to use (enter as number): ${green}\c"
		read configChoice
		echo -e "${noColor}\c"
		fileChosen=`echo ${configFileArray[$configChoice]}`
		if [[ "$fileChosen" != '' ]]; then
			for i in $(cat Config/$fileChosen.config); do
				declare `echo $i | grep -o "[^:]*:" | grep -o "[^:]*"`=`echo $i | grep -o ":[^;]*" | grep -o "[^:]*"`
			done
			break
		fi
		echo -e "${red}$configChoice is not a valid choice."
	done	
}

#Save to configuration file
function saveConfig {
	echo -e "\nSave these steps into config file (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
	read saveConfig
	echo -e "${noColor}"

	if [[ `echo "$saveConfig" | tr [:upper:] [:lower:]` == 'y' ]]; then
		echo -e "Enter a name for your config file: ${green}\c"
		read configName
		echo -e "${noColor}"	
		echo "instanceID:$instanceID;" > Config/$configName.config
		echo "appType:$appType;" >> Config/$configName.config
		echo "targetPath:$targetPath;" >> Config/$configName.config
		echo "serviceType:$serviceType;" >> Config/$configName.config
		echo "dbBackup:$dbBackup;" >> Config/$configName.config
		if [[ `echo "$dbBackup" | tr [:upper:] [:lower:]` == "y" ]]; then 
			echo "hostName:$hostName;" >> Config/$configName.config
			echo "dbName:$dbName;" >> Config/$configName.config
			echo "dbuser:$dbuser;" >> Config/$configName.config
			echo "dbpass:$dbpass;" >> Config/$configName.config
		fi
		echo -e "${yellow}Your \"$configName.config\" file is saved.${noColor}"
	fi
}

#Read configuration from Config folder. This Config folder must existed for this function to work.
function readConfig {
	echo -e "\n${yellow}List of available config files:"
	listConfigFile=`ls Config/*.config | grep Config | grep -o "/[^.]*" | grep -o [^/]*`
	#if it's not empty then proceed
	if [[ $listConfigFile ]]; then
		let count=0
		for i in $(echo $listConfigFile | tr " " "\n"); do
			let count+=1
			echo "$count. $i"
			configFileArray["$count"]="$i"
		done
		while true; do		
			echo -e "${noColor}"
			echo -e "Which config file you want to use (enter as number): ${green}\c"
			read configChoice
			echo -e "${noColor}\c"
			fileChosen=`echo ${configFileArray[$configChoice]}`
			if [[ "$fileChosen" != '' ]]; then
				for i in $(cat Config/$fileChosen.config); do
					declare `echo $i | grep -o "[^:]*:" | grep -o "[^:]*"`=`echo $i | grep -o ":[^;]*" | grep -o "[^:]*"`
				done
				break
			fi
			echo -e "${red}$configChoice is not a valid choice."
		done
		break
	else
		echo -e "${yellow}There is no files in this Config folder.${noColor}"
	fi		
}


echo -e "\n${lCyan}*******************************************************************************" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*                           AWS DEPLOY TOOL v2.01                              *" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*******************************************************************************${noColor}" 

#Ask for AWS crediential.
credentialCheck

#Choose methods to deploy
echo -e "\nDeploy your application using?\n "
echo -e "${yellow}1. User's input.         2. From pre-defined config file.${noColor}"
while true; do
	echo -e "\nYour choice: ${green}\c"
	read deployOpt
	echo -e "${noColor}\c"
	if [[ "$deployOpt" == "1" ]]; then

		#Choose the instance to deploy
		inputInstanceID

		#Choose type of application.
		appTypeChoice

		#Choose deployment folder.
		targetDeploymentPath

		#Back up Database
		dbBackupFunct
		break

	elif [[ "$deployOpt" == "2" ]]; then
		
		#Run from config files
		echo -e "\n${yellow}List of available config files:"
		listConfigFile=`ls Config/*.config | grep Config | grep -o "/[^.]*" | grep -o [^/]*`
		#if it's not empty then proceed
		if [[ $listConfigFile ]]; then
			let count=0
			for i in $(echo $listConfigFile | tr " " "\n"); do
				let count+=1
				echo "$count. $i"
				configFileArray["$count"]="$i"
			done
			while true; do		
				echo -e "${noColor}"
				echo -e "Which config file you want to use (enter as number): ${green}\c"
				read configChoice
				echo -e "${noColor}\c"
				fileChosen=`echo ${configFileArray[$configChoice]}`
				if [[ "$fileChosen" != '' ]]; then
					for i in $(cat Config/$fileChosen.config); do
						declare `echo $i | grep -o "[^:]*:" | grep -o "[^:]*"`=`echo $i | grep -o ":[^;]*" | grep -o "[^:]*"`
					done
					break
				fi
				echo -e "${red}$configChoice is not a valid choice."
			done
			break
		else
			echo -e "${yellow}There is no files in this Config folder.${noColor}"
		fi		
	else
		echo -e "${red}$deployOpt is a not valid choice.${noColor}"
	fi
done

#Display configuration
echo -e "\nDeploy your application with the following configuration:"
echo -e "\n${yellow}Instance ID: ${green}$instanceID"
echo -e "${yellow}App's type: ${green}$appType"
echo -e "${yellow}Target deployment path: ${green}$targetPath"
if [[ `echo "$dbBackup" | tr [:upper:] [:lower:]` == "y" ]]; then 
	echo -e "${yellow}Database backup: ${green}Yes"
	echo -e "${yellow}DB's host name: ${green}$hostName"
	echo -e "${yellow}DB name: ${green}$dbName"
	echo -e "${yellow}Username: ${green}$dbuser"
	echo -e "${yellow}Password: ${green}Nope. You can't see me !!!${noColor}"
else
	echo -e "${yellow}Database backup: ${green}No${noColor}"
fi

#Comfimation creation.
while true; do
	echo -e "\nComfirm (${green}Y${noColor}/${green}N${noColor})? ${green}\c" 
	read comfirmation
	echo -e "${noColor}\c"
	if [[ `echo "$comfirmation" | tr [:upper:] [:lower:]` == "y" ]]; then

		#Get current date
		currentDate=`date '+%m-%d-%Y'`

		#Get the selected instance
		currentInstance=`aws ec2 describe-instances --filters Name=instance-id,Values=$instanceID `

		#Get Ip of current selected instance
		instanceIP=`echo "$currentInstance" | grep -o "PublicIpAddress[^,]*" | grep -o [0-9].*[0-9]`

		#Get keypair name for your instance and set it to private.
		instanceKey=`echo "$currentInstance" | grep "KeyName" | grep -o ": \".*" | grep -o '[0-9a-zA-Z]*'`
		chmod 400 Key/"$instanceKey".pem

		#Sync local files to remote deploy folder.
		ssh -i key/"$instanceKey".pem ubuntu@"$instanceIP" 'bash -s' < 'bin/deployfolder.sh'
		echo -e "\n${yellow}Syncing local files to remote server.....${noColor}\n"

		scp -i key/"$instanceKey".pem -r Deploy/* ubuntu@"$instanceIP":~/Deploy

		echo -e "\n${yellow}Begin to back up and deploy new changes.....${noColor}\n"

		#Modify execDeploy script with current configuration
		cp bin/template.sh bin/execbackup.sh
		sed -i "s,<app-type>,$appType,g" bin/execbackup.sh
		sed -i "s,<target-deploy>,$targetPath,g" bin/execbackup.sh
		sed -i "s,<service-type>,$serviceType,g" bin/execbackup.sh
		sed -i "s,<current-date>,$currentDate,g" bin/execbackup.sh
		
		#Begin to deploy
		ssh -i Key/"$instanceKey".pem ubuntu@"$instanceIP" 'bash -s' < 'bin/execbackup.sh'

		#Run database backup
		if [[ `echo "$dbBackup" | tr [:upper:] [:lower:]` == "y" ]]; then 			
			mysqldump -u $dbuser -p$dbpass -h $hostName $dbName > bin/dbscript/$dbName-$currentDate.sql
			scp -i key/"$instanceKey".pem -r bin/dbscript ubuntu@"$instanceIP":~/Backup/$appType/$currentDate
		fi

		echo -e "\n${yellow}Deploy and Backup completed.${noColor}"
		break
	elif [[ `echo "$comfirmation" | tr [:upper:] [:lower:]` == "n" ]]; then
		exit
	fi
	echo -e "${red}$comfirmation is not a valid choice. ${noColor}"
done

#Save configuration in config to reuse.
if [[ "$deployOpt" == "1" ]]; then
	saveConfig
fi