#!/bin/sh

echo "#####################################################"
echo " Service application security checker"
echo " By: Rusty"
echo " Creation date: 2017.11.16"
echo " Version: 4.0"
echo "#####################################################"

RESULT_FILE="/tmp/WACS_RESULT.txt"
ERROR_FILE="/tmp/WACS_ERROR.txt"
ARG=$1

COMMANDS=("uname -a" "hostname" "netstat -ntpl")

for COM in "${COMMANDS[@]}"
do
	echo "####################i $COM  #####################" >>$RESULT_FILE
	{
		echo "----- COMMAND: $COM -----"
		$COM 1>>$RESULT_FILE 2>>$RESULT_FILE
		echo "`date`--SUCCESSFUL!--$COM"
	} || {
		echo "`date`--ERROR--$COM"
	}
	echo "##############################################" >>$RESULT_FILE
done

echo "################## PS AUX #####################" >>$RESULT_FILE
if [ ! -z "${ARG}" ]; then
		echo "----- COMMAND: ps aux | grep $ARG  -----"
		ps aux | grep $ARG >>$RESULT_FILE
		echo "##############################################" >>$RESULT_FILE
		echo "################## PS AUX FIND FOLDERS #####################" >>$RESULT_FILE
		ps aux | grep $ARG >>PS_AUX.txt
		# egrep -o '([/]{1}[a-zA-Z0-9._\-]*){1,}'
		GREP_RES=$(egrep -o '([/]{1}[a-zA-Z0-9._\-]*){1,}' PS_AUX.txt)	
		rm PS_AUX.txt
		echo "------------"
		while read -r line; do
			if [[ $line == *"$ARG"*  ]]; then
				echo "$line" >>$RESULT_FILE
				
			fi
		done <<< "$GREP_RES"
		echo "------------"
		
		echo "`date`--SUCCESSFUL!--$ARG"
else
	echo "Nincs megadva argumentum! (wildfly | postgre)"
fi
echo "##############################################" >>$RESULT_FILE
if [[ $ARG == *"wildfly"* ]]; then
	echo "################### WILDFLY ######################" >>$RESULT_FILE
	mkdir /home/govcert1/wildfly_conf/
	cp -a /opt/wildfly/standalone/configuration /home/govcert1/wildfly_conf/configuration
	cp -a /opt/wildfly/standalone/data /home/govcert1/wildfly_conf/data
	cp -a /opt/wildfly/standalone/deployments /home/govcert1/wildfly_conf/deployments
	cp -a /opt/wildfly/standalone/lib /home/govcert1/wildfly_conf/lib
	cp -a /opt/wildfly/standalone/tmp /home/govcert1/wildfly_conf/tmp
	cp -a /opt/wildfly/bin /home/govcert1/wildfly_conf/bin
	echo "tar -czvf /home/govcert1/wildfly_scurity.tar.gz OK!" >>$RESULT_FILE
	echo "##############################################" >>$RESULT_FILE
	echo "#######################wget http://localhost:8080#######################" >>$RESULT_FILE
	wget http://localhost:8080 2>>$RESULT_FILE
	cat index.html >>$RESULT_FILE
	rm index.html
	echo "##############################################" >>$RESULT_FILE
	echo "#######################wget https://localhost:8443#######################" >>$RESULT_FILE
	wget --no-check-certificate https://localhost:8443 2>>$RESULT_FILE
	cat index.html >>$RESULT_FILE
	rm index.html
	echo "##############################################" >>$RESULT_FILE
	echo "#######################wget https://localhost:9993#######################" >>$RESULT_FILE
	wget --no-check-certificate https://localhost:9993 2>>$RESULT_FILE
	cat index.html >>$RESULT_FILE
	rm index.html
	mv $RESULT_FILE /home/govcert1/wildfly_conf/
	tar -czvf /home/govcert1/wildfly_scurity.tar.gz /home/govcert1/wildfly_conf/*
	echo "##############################################" >>$RESULT_FILE
	rm -r /home/govcert1/wildfly_conf/
fi
if [[ $ARG == *"postgre"* ]]; then
	#mkdir ~/postgres_conf/
	echo -e "\nPostgreSQL packages:" >>$RESULT_FILE
	rpm -qa | grep postgre >>$RESULT_FILE
	echo -e "\nPostgreSQL services:" >>$RESULT_FILE
	sudo systemctl is-enabled postgresql >>$RESULT_FILE
	sudo systemctl status postgresql >>$RESULT_FILE
	binary_start=$(grep -i "execstart=" /usr/lib/systemd/system/postgresql.service | cut -d '=' -f 2 | cut -d ' ' -f 1)
	echo -e "\nPostgreSQL binary location: $binary_start" >>$RESULT_FILE
	postgres_home=$(grep postgres /etc/passwd | awk -F':' '{print$6}')
	echo -e "\nPostgreSQL user home directory: $postgres_home" >>$RESULT_FILE
	sudo cp postgre_script.sh /tmp/
	sudo su - postgres -c "bash /tmp/postgre_script.sh"
	sudo rm /tmp/postgre_script.sh
fi	
