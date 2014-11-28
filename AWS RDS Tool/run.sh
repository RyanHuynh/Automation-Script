#AWS RDS TOOL 
#Created by Ryan Huynh
#Version 1.0

#!/bin/bash 
# Some ultilities variables
yellow='\e[1;33m'
lCyan='\e[1;36m'


noColor='\e[0m'
red='\e[0;31m'
green='\e[0;32m'
bold=`tput bold`
dbInstanceClassList=" db.t2.micro db.m1.small db.m3.medium db.m3.large db.m3.xlarge db.m3.2xlarge db.r3.large db.r3.xlarge db.r3.2xlarge db.r3.4xlarge db.r3.4xlarge db.r3.8xlarge db.t2.micro db.t2.small db.t2.medium db.m2.xlarge db.m2.2xlarge db.m2.4xlarge db.cr1.8xlarge db.m1.medium db.m1.large db.m1.xlarge "
dbEngine=" MySQL postgres oracle-se1 oracle-se oracle-ee sqlserver-ee sqlserver-se sqlserver-ex $engine sqlserver-web "
instanceCreated=false

#Functions for this app
#Function to check for credential. Crediential only need to enter one, unless you change to different region
function credentialCheck {
	while true; do
		echo -e "\nYou need to configure your AWS crediential first, configure your crediential now (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
		read userInput
		echo -e "${noColor}\c"
		if [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "y" ]]; then
			echo -e "${red}${bold}NOTE: ${noColor}For region, please specify the region in which your instance lives (e.g. us-west-1)\n"
			aws configure			
			break
		elif [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "n" ]]; then
			break
		fi
		echo -e "${red}$userInput is not a valid choice. ${noColor}"
	done
}

#Function to create an instance name. Instance name created must not be unique. Name must be only letter, digits, or hyphen.
function createInstanceName {
	while true; do
		while true; do
			echo -e "\nEnter a unique name for your DB instance: ${green}\c" 
			read instanceId
			echo -e "${noColor}\c"
			if [[ `echo $instanceId | grep "^[a-zA-Z0-9\-]*$"` ]]; then	
				break
			fi
			echo -e "${red}$instanceId is not a valid id name.${noColor}"
		done

		#Check to see if the id is already exist
		nameValid=`aws rds describe-db-instances | grep '"DBInstanceIdentifier"'`
		if [[ `echo "$nameValid" | grep \""$instanceId"\"` ]]; then
			echo -e "${red}This instance name \""$instanceId"\" is already existed in this region.${noColor}"
		else			
			break
		fi
	done
}

#Function to create master username. Must start with a letter and follow by letters, digits, or _ and must be at least 2 chars.
function createMasterName {
	while true; do
		echo -e "\nEnter master's username for your db: ${green}\c" 
		read username
		echo -e "${noColor}\c"
		if [[ `echo $username | grep "^[a-zA-Z][a-zA-Z0-9\_][a-zA-Z0-9\_]*$"` ]]; then	
			break
		fi
		echo -e "${red}$username is not a valid name.${noColor}"
	done
}

#Function to create password for master username. Must be at least 8 chars.
function createPassword {
	while true; do
	while true; do
		echo -e "\nEnter master's password: \c"
		read -s password
		if [[ `echo $password | grep "^........*$"` ]]; then	
			break
		fi
		echo -e "${red}\nMaster's password must be at least 8 chars.${noColor}"
	done	
	echo -e "\nRe-enter master's password: \c"
	read -s repassword
	if [[ "$password" == "$repassword" ]]; then
		echo ''
		break
	else
		echo -e "\n${red}Password does not match. Please reenter password.${noColor}"
	fi
	done
}

#Define database engine for your instance
function instanceEngine {
	while true; do
		echo -e "\nType of DB engine( ${green}-help${noColor} to display valid options ): ${green}\c" 
		read engine
		echo -e "${noColor}\c"
		if [[ "$engine" == "-help" ]]; then
			echo -e "\n${yellow}MySQL           postgres       oracle-se1"
			echo               "oracle-se       oracle-ee      sqlserver-ee"
			echo -e			   "sqlserver-se    sqlserve-ex    sqlserver-web${noColor}"
		elif [[ `echo "$dbEngine" | grep " $engine "` ]] && [[ `echo "$engine" | tr -d ''` != `echo ''` ]]; then
			break
		else
			echo -e "${red}${engine} is not a valid option.${noColor}"
		fi
	done
}

#Instance type for your instance. Valid type are defined in dbInstanceClassList variable above. NEED TO CHECK FOR UPDATE.
function instanceType {
	while true; do
		echo -e "\nInstance class: ${green}\c" 
		read instanceClass
		echo -e "${noColor}\c"
		if [[ "$instanceClass" == "-help" ]]; then
			echo -e "${yellow}Please refer to http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html for more details.${noColor}"			
		elif [[ `echo "$dbInstanceClassList" | grep " $instanceClass "` ]]; then
			break
		else
			echo -e "${red}${instanceClass} is not a supported instance class.${noColor}"
		fi
	done
}

#Define allocated memory for your instance. EACH DATABSE ENGINE HAS DIFFERENT MIN AND MAX VALUE (IT'S UP TO DATE AS 11/24/2014)
function instanceMemory {
	while true; do
		echo -e "\nAllocated storage value in GB ( ${green}-help${noColor} if you are clueless ): ${green}\c" 
		read allocatedStorage
		echo -e "${noColor}\c"
		if [[ "$allocatedStorage" == "-help" ]]; then
			echo -e "\n${yellow}MySQL and PostgreSQL: must be an integer between 5 and 3072. ${noColor}"
			echo -e "${yellow}Oracle: must be an integer between 10 and 3072. ${noColor}"	
			echo -e "${yellow}SQL Server : must be an integer between 200 and 1024 (sqlserver-se and sqlserver-ee) or from 20 to 1024 (sqlserver-ex and sqlserver-web). ${noColor}"	
		elif [[ `echo "$allocatedStorage" | tr -d ''` == `echo ''`  ]]; then
			echo -e "${red}Allocated storage can not be empty.${noColor}"
		elif [[ "$engine" == "MySQL" ]] || [[ "$engine" == "postgres" ]]; then
			if (( $allocatedStorage < 5 )) || (( $allocatedStorage > 3072 )); then
				echo -e "${red}$allocatedStorage is not valid value for $engine engine.${noColor}"
			else
				break
			fi
		elif [[ "$engine" == "oracle-se1" ]] || [[ "$engine" == "oracle-ee" ]] || [[ "$engine" == "oracle-se" ]]; then
			if (( $allocatedStorage < 10 )) || (( $allocatedStorage > 3072 )); then
				echo -e "${red}$allocatedStorage is not valid value for $engine engine.${noColor}"
			else
				break
			fi
		elif [[ "$engine" == "sqlserver-se" ]] || [[ "$engine" == "sqlserver-ee" ]]; then
			if (( $allocatedStorage < 200 )) || (( $allocatedStorage > 1024 )); then
				echo -e "${red}$allocatedStorage is not valid value for $engine engine.${noColor}"
			else
				break
			fi
		elif [[ "$engine" == "sqlserver-ex" ]] || [[ "$engine" == "sqlserver-web" ]]; then
			if (( $allocatedStorage < 20 )) || (( $allocatedStorage > 1024 )); then
				echo -e "${red}$allocatedStorage is not valid value for $engine engine.${noColor}"
			else
				break
			fi
		fi
	done
}

#Function to save configuration for this application.
function saveConfig {
	echo -e "\nSave these steps into config file (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
	read saveConfig
	echo -e "${noColor}"

	if [[ `echo "$saveConfig" | tr [:upper:] [:lower:]` == 'y' ]]; then
		echo -e "Enter a name for your config file: ${green}\c"
		read configName
		echo -e "${noColor}"	

		#Attributes save here should match all varibles you defined above. (e.g. amiID, keyPair)
		echo "engine:$engine;" > Config/$configName.config
		echo "instanceClass:$instanceClass;" >> Config/$configName.config
		echo "allocatedStorage:$allocatedStorage;" >> Config/$configName.config
		
		echo -e "${yellow}Your \"$configName.config\" file is saved.${noColor}"
	fi
}

echo -e "\n${lCyan}*******************************************************************************" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*                            AWS RDS TOOL v1.0                                *" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*******************************************************************************${noColor}" 

#Ask for AWS crediential.
credentialCheck

#Database instance name.
createInstanceName

#master username for your instance.
createMasterName

#master password for your instance.
createPassword

#RDS DB configuration options
while [[ "$instanceCreated" == false ]]; do
	echo -e "\nGenerate RDS database using configuration from :\n "
	echo -e "${yellow}1. User's input.         2. From pre-defined config file.${noColor}"
	while true; do
		echo -e "\nYour option: ${green}\c"
		read deployOpt
		echo -e "${noColor}\c"

		#Create database from user's input
		if [[ "$deployOpt" == "1" ]]; then
			
			#Define type of database instance
			instanceEngine

			#Define instance classes 
			instanceType

			#Define allocated storage value
			instanceMemory

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
			echo -e "${red}Please choose option 1 or 2.${noColor}"
		fi
	done

	#Comfirm creation with defined configuration
	echo -e "\n${bold}Create database with the following configuration:${noColor}\n"
	echo -e "${yellow}Instance ID: ${green}$instanceId"
	echo -e "${yellow}Master's username: ${green}$username"
	echo -e "${yellow}Database Engine: ${green}$engine"
	echo -e "${yellow}Instance class: ${green}$instanceClass"
	echo -e "${yellow}Allocated Storage size ( GB ): ${green}$allocatedStorage"
	echo -e "${noColor}"	
	
	while true; do
		echo -e "Confirm creation (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
		read confirm
		echo -e "${noColor}"
		if [[ `echo "$confirm" | tr [:upper:] [:lower:]`  == "y" ]]; then
			echo -e "${yellow}Creating database instance ....${noColor}"
			let instanceCreated=true
			aws rds create-db-instance --db-instance-identifier "$instanceId" --allocated-storage "$allocatedStorage" --db-instance-class "$instanceClass" --engine "$engine" --master-username "$username" --master-user-password "$password"
			break
		elif [[ `echo "$confirm" | tr [:upper:] [:lower:]` == "n" ]]; then
			exit			
		fi
			echo -e "${red}$confirm is not a valid option."
	done
done

#Save configuration to config file.
if [[ "$deployOpt" == "1" ]]; then
	saveConfig
fi
