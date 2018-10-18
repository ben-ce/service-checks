#!/bin/sh

echo "#####################################################"
echo " Wildfly application security checker"
echo " By: Rusty"
echo " Creation date: 2017.11.16"
echo " Version: 1.0"
echo "#####################################################"

RESULT_FILE="WACS_RESULT.txt"
ERROR_FILE="WACS_ERROR.txt"
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
	echo "Nincs megadva argumentum!"
fi
echo "##############################################" >>$RESULT_FILE
if [[ $ARG == *"wildfly"* ]]; then
	echo "################### WILDFLY ######################" >>$RESULT_FILE
	mkdir /tmp/wildfly_conf/
	cp -a /opt/wildfly/standalone/configuration /tmp/wildfly_conf/configuration
	cp -a /opt/wildfly/standalone/data /tmp/wildfly_conf/data
	cp -a /opt/wildfly/standalone/deployments /tmp/wildfly_conf/deployments
	cp -a /opt/wildfly/standalone/lib /tmp/wildfly_conf/lib
	cp -a /opt/wildfly/standalone/tmp /tmp/wildfly_conf/tmp
	cp -a /opt/wildfly/bin /tmp/wildfly_conf/bin
	echo "tar -czvf /tmp/wildfly_scurity.tar.gz OK!" >>$RESULT_FILE
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
	mv $RESULT_FILE /tmp/wildfly_conf/
	tar -czvf /tmp/wildfly_scurity.tar.gz /tmp/wildfly_conf/*
	echo "##############################################" >>$RESULT_FILE
	rm -r /tmp/wildfly_conf/
fi
if [[ $ARG == *"postgre"* ]]; then
	echo -e "\nPostgreSQL packages:" >>$RESULT_FILE
	rpm -qa | grep postgre >>$RESULT_FILE
	echo -e "\nPostgreSQL services:" >>$RESULT_FILE
	sudo systemctl is-enabled postgresql-9.6 >>$RESULT_FILE
	sudo systemctl status postgresql-9.6 >>$RESULT_FILE
	binary_start=$(grep -i "execstart=" /usr/lib/systemd/system/postgresql-9.6.service | cut -d '=' -f 2 | cut -d ' ' -f 1)
	echo -e "\nPostgreSQL binary location: $binary_start" >>$RESULT_FILE
	postgres_home=$(grep postgres /etc/passwd | awk -F':' '{print$6}')
	echo -e "\nPostgreSQL user home directory: $postgres_home" >>$RESULT_FILE
	chmod 777 $RESULT_FILE
	chmod 777 $ERROR_FILE
	sudo cp pgsql_script.sh $postgres_home && sudo chown postgres:postgres $postgres_home/pgsql_script.sh
	sudo -i -u postgres -H bash -c "bash pgsql_script.sh"
	sudo rm $postgres_home/pgsql_script.sh
fi	
