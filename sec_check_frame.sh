#!/bin/sh

echo "#####################################################"
echo " Service application security checker"
echo "#####################################################"

RESULT_FILE="/tmp/WACS_RESULT.txt"
ERROR_FILE="/tmp/WACS_ERROR.txt"
ARG=$1

# determine OS version
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo "$OS - $VER" >>$RESULT_FILE


COMMANDS=( "hostname" "netstat -ntpl")

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
	mkdir $HOME/wildfly_conf/
	cp -a /opt/wildfly/standalone/configuration $HOME/wildfly_conf/configuration
	cp -a /opt/wildfly/standalone/data $HOME/wildfly_conf/data
	cp -a /opt/wildfly/standalone/deployments $HOME/wildfly_conf/deployments
	cp -a /opt/wildfly/standalone/lib $HOME/wildfly_conf/lib
	cp -a /opt/wildfly/standalone/tmp $HOME/wildfly_conf/tmp
	cp -a /opt/wildfly/bin $HOME/wildfly_conf/bin

	echo "##############################################" >>$RESULT_FILE

    # TODO végigjárni a java process által nyitott portok
    

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
	mv $RESULT_FILE $HOME/wildfly_conf/
	tar -czvf $HOME/wildfly_security.tar.gz $HOME/wildfly_conf/* && rm -rf $HOME/wildfly_conf/
	echo "tar -czvf $HOME/wildfly_security.tar.gz OK!" >>$RESULT_FILE
	echo "##############################################" >>$RESULT_FILE
fi
if [[ $ARG == *"postgre"* ]]; then
	#mkdir ~/postgres_conf/
	echo -e "\nPostgreSQL packages:" >>$RESULT_FILE
    # determine package manager and check postgresql packages
    if [[ $OS=="Debian" || $OS=="Ubuntu" ]];then
        dpkg-query --list *postgre >>$RESULT_FILE
    
    elif [[ $OS=="Red Hat" || $OS=="CentOS" || $OS=="openSUSE"]];then
        rpm -qa | grep postgre >>$RESULT_FILE
    fi

	echo -e "\nPostgreSQL services:" >>$RESULT_FILE

    # az 1-es process id-val rendelkezo process meghatarozasa
    initsys=ls -l `ps -h 1 | column -t | awk -F' ' '{print$5}'` | awk '{print $NF}' | tr -d '^.'

    #logika, ami eldonti, hogy mi vezerli a postgresql service-t
    if [[ $initsys == *"systemd"* ]];then
        echo -e "\nUsing systemd." >>$RESULT_FILE
        sudo systemctl is-enabled postgresql >>$RESULT_FILE
        systemctl status postgresql >>$RESULT_FILE
        binary_start=$(grep -i "execstart=" /usr/lib/systemd/system/postgresql.service | cut -d '=' -f 2 | cut -d ' ' -f 1)
        echo -e "\nPostgreSQL binary location: $binary_start" >>$RESULT_FILE

    elif [[ $initsys == *"init"* ]];then
        echo -e "\nUsing Upstart or SysVinit, check init files manually (/etc/rc.d/init.d/ ... )" >>$RESULT_FILE
        service postgresql status >>$RESULT_FILE
    else echo -e "\nUsing not supported init system" >>$RESULT_FILE
    fi

	postgres_home=$(grep postgres /etc/passwd | awk -F':' '{print$6}')
	echo -e "\nPostgreSQL user home directory: $postgres_home" >>$RESULT_FILE
	sudo cp postgre_script.sh /tmp/
	sudo su - postgres -c "bash /tmp/postgre_script.sh"
	sudo rm /tmp/postgre_script.sh
fi	
