#!/bin/bash
# Some ultilities variables
yellow='\e[1;33m'
lCyan='\e[1;36m'
noColor='\e[0m'
red='\e[0;31m'
green='\e[0;32m'
#NEED TO RECHECK THOSE VALUE
ec2InstanceTypeList=" t2.micro m1.small m3.medium m3.large m3.xlarge m3.2xlarge r3.large r3.xlarge r3.2xlarge r3.4xlarge r3.4xlarge r3.8xlarge t2.micro t2.small t2.medium m2.xlarge m2.2xlarge m2.4xlarge cr1.8xlarge m1.medium m1.large m1.xlarge "

#Function for this app
#Function to check for credential. Crediential only need to enter one, unless you change to different region
function credentialCheck {
	while true; do
		echo -e "You need to configure your AWS crediential first, configure your crediential now (${green}Y${noColor}/${green}N${noColor})? ${green}\c"
		read userInput
		echo -e "${noColor}\c"
		if [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "y" ]]; then
			echo -e "${red}${bold}NOTE: ${noColor}${normal}For region, please specify the region in which your instance lives (e.g. us-west-1)\n"
			aws configure
			echo ''
			break
		elif [[ `echo "$userInput" | tr [:upper:] [:lower:]` == "n" ]]; then
			echo ''
			break
		fi
		echo -e "${red}$userInput is not a valid choice. ${noColor}"
	done
}

#AMI of your instance. STILL NEED TO CHECK VALIDATION
function instanceAMI {
	while true; do
		echo -e "Enter AMI for your instance (${green} -default ${noColor}for AWS default AMI ${green}-custom ${noColor} for custom AMI): ${green}\c"
		read amiID
		echo -e "${noColor}\c"
		if [[ "$amiID" == "-default" ]]; then
			echo -e "\n${yellow}AWS default EC2 AMI id:"
			echo -e "Amazon Linux AMI 2014.09.01: ${green}ami-4b6f650e"
			echo -e "${yellow}Ubuntu Server 14.04: ${green}ami-076e6542"
			echo -e "${yellow}Microsoft Windows Server 2012 R2 Base: ${green}ami-df43569a${noColor}\n"
		elif [[ "$amiID" == "-custom" ]]; then
			echo -e "\n${yellow}Custom AMI id:"
			amiList=`aws ec2 describe-images --owners self` 
			for i in $(echo $amiList | grep "ImageId" |  grep -o ami-[^\"]*); do
				amiName=`aws ec2 describe-images --image-ids $i | grep \"Name\" | grep -o :[^,]* | grep -o "[a-zA-Z0-9]*"`
				echo -e "${yellow}$amiName: ${green}$i"
			done
			echo -e "${noColor}"
		else
			echo ''
			break
		fi			
	done
}

#Instance type. The default list for instance type is defined above. Please check for instance type update !
function instanceType {
	while true; do
		echo -e "Choose an instance type for your instance: ${green}\c"
		read instanceType
		echo -e "${noColor}\c"
		if [[ "$instanceType" == "-help" ]]; then
			echo -e "${yellow}Please refer to http://aws.amazon.com/ec2/instance-types/ for more details.${noColor}\n"	
		elif [[ `echo "$ec2InstanceTypeList" | grep " $instanceType "` ]]; then
			echo ''
			break
		else
			echo -e "${red}${instanceType} is not a supported instance type.${noColor}\n"
		fi
	done
}

#Choose a key pair for your instance or create a new one
function instanceKeyPair {
	while true; do
		echo -e "Choose a key-pair for your instance( ${green}-list${noColor} to display available keys, ${green}-new ${noColor}to create a new key): ${green}\c"
		read keyPair
		echo -e "${noColor}\c"
		if [[ "$keyPair" == "-list" ]]; then
			echo -e "\n${yellow}Available key-pair: \c"
			for i in $(aws ec2 describe-key-pairs | grep "KeyName" | grep -o :'\s'\"[a-zA-Z0-9]* | grep -o "[a-zA-Z0-9]*"); do
				echo -e "${green}$i \c"
			done
			echo -e "${noColor}\n"
		elif [[ "$keyPair" == "-new" ]]; then
			let newKey=true;
			echo -e "Create new key-pair: ${green}\c"
			read keyPair
			echo -e "${noColor}\c"	
			echo -e "${yellow}Your key will be created and saved in the Key folder.${noColor}"
			break
		else
			break
		fi
	done
}

#Read configuration from Config folder. This Config folder must existed for this function to work.
function readConfig {
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
		echo "amiID:$amiID;" >> Config/$configName.config
		echo "instanceType:$instanceType;" > Config/$configName.config
		echo "keyPair:$keyPair;" >> Config/$configName.config
		
		echo -e "${yellow}Your \"$configName.config\" file is saved.${noColor}"
	fi
}


echo -e "\n${lCyan}*******************************************************************************" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*                              AWS EC2 TOOL v1.0                              *" 
echo -e   "${lCyan}*                                                                             *" 
echo -e   "${lCyan}*******************************************************************************\n${noColor}" 

#Ask for AWS crediential.
credentialCheck

#Add a name tags for your instance
echo -e "Enter a name for your instance: ${green}\c"
read ec2Name
echo -e "${noColor}"

#Choose methods to create instance
echo -e "Create your instance using?\n "
echo -e "${yellow}1. User's input.         2. From pre-defined config file.${noColor}\n"
while true; do
	echo -e "Your choice: ${green}\c"
	read deployOpt
	echo -e "${noColor}"

	#Manually input 
	if [[ "$deployOpt" == "1" ]]; then

		#Choose an AMI id for you instance: [TO-DO catch incorrect ami id]
		instanceAMI

		#Choose instance type
		instanceType

		#Choose akeypair for your instance.
		instanceKeyPair

		break

	elif [[ "$deployOpt" == "2" ]]; then
		
		#Run from config files
		readConfig
		break
	fi
	echo -e "${red}$deployOpt is a not valid choice.${noColor}"
done

#Display configuration
echo -e "\nCreate your instance with the following configuration:"
echo -e "\n${yellow}Instance Name: ${green}$ec2Name"
echo -e "${yellow}Instance's AMI: ${green}$amiID"
echo -e "${yellow}Instance's type: ${green}$instanceType"
echo -e "${yellow}Keypair Name: ${green}$keyPair${noColor}"

#Do creation here

#Create key here if needed
if [[ newKey ]]; then
	aws ec2 create-key-pair --key-name "$keyPair" | grep -o "\-\-\-\-\-BEGIN RSA PRIVATE KEY\-\-\-\-\-[^-]*\-\-\-\-\-END RSA PRIVATE KEY\-\-\-\-\-" > Key\\"$keyPair".pem
	sed -i 's,\\n,\n,g' Key\\"$keyPair".pem
fi

#Save configuration to config file.
if [[ "$deployOpt" == "1" ]]; then
	saveConfig
fi