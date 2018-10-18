#!/bin/bash

echo
echo "# arguments called with ---->  ${@}     "
echo "# path to me --------------->  ${0}     "
echo "# my name ------------------>  ${0##*/} "
echo

#wildfly user and groups
egrep "wildfly|jboss" /etc/passwd | awk -F':' '{print$1}'
groups $(egrep "wildfly|jboss" /etc/passwd | awk -F':' '{print$1}') | awk -F' ' '{print$3}'

#wildfly service
systemctl status wildfly*

#wildfly processzek beazonosítása (java)
    ps -ef | grep java

#wildfly által nyitott kommunikációs portok beazonosítása
    #netstat és process lista alapján
    #kiváncsiak vagyunk a http/https és a console portokra
    sudo su - wildfly netstat -tnlp | grep java

#wildfly által használt kommunikációs protokollok meghatározása
    #standalone.xml vagy domain.xml által definiált http-listener és https-listener alapján
    #használ-e https-t vagy csak simán http protokollt engedélyeztek az előbb feltárt portokon
    cp $JAVA_HOME $CATALINA_HOME

#wildfly config hardening checks
    #checking config properties files
        # megnézni milyen properties file-okat használnak a standalone.xml, domain.xml és host.xml szintaxisban
        # megnézni, hogy a process a '-P' kapcsolóval milyen file-okat használ

    #checking password storing method (plaintext,hash,vault)

exit
