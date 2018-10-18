#!/bin/bash
#module checks
RESULT_FILE=/tmp/apache_findings
touch $RESULT_FILE
echo -e "\n--==Apache2 module checks==--"  >$RESULT_FILE
sudo -s bash -- << EOF 
httpd -M | grep log_config  >>$RESULT_FILE
httpd -M | egrep ' dav_[[:print:]]+module'  >>$RESULT_FILE
httpd -M | egrep 'status_module'  >>$RESULT_FILE
httpd -M | grep autoindex_module  >>$RESULT_FILE
httpd -M | grep proxy_  >>$RESULT_FILE
httpd -M | grep userdir_  >>$RESULT_FILE
httpd -M | egrep 'info_module'  >>$RESULT_FILE
httpd -M | egrep 'ssl_module|nss_module'  >>$RESULT_FILE
a2enmod -l | grep -o -P "security[\d]"  >>$RESULT_FILE
EOF


#permission checks
echo -e "\n--==Permission checks==--" >>$RESULT_FILE
echo -e "\nApache2 User from config files:" >>$RESULT_FILE
grep -r -i '^User' /etc/apache2/ >>$RESULT_FILE

echo -e "\nApache2 User Group from config files:" >>$RESULT_FILE
grep -r -i '^Group' /etc/apache2/ >>$RESULT_FILE

echo -e "\nNormal system users minimum id:" >>$RESULT_FILE
grep "^UID_MIN" /etc/login.defs >>$RESULT_FILE
APACHE2_USER=$(egrep "www|apache" /etc/passwd | awk -F':' '{print$1}') >>$RESULT_FILE
echo -e "\nApache2 User id" >>$RESULT_FILE
id $APACHE2_USER >>$RESULT_FILE
echo -e "\nApache2 User Group" >>$RESULT_FILE
APACHE2_GROUP=$(groups wwwrun | awk -F':' '{print$2}' | cut -d' ' -f2) >>$RESULT_FILE
echo $APACHE2_GROUP >>$RESULT_FILE

#httpd process run as
echo -e "\n--==User checks==--" >>$RESULT_FILE
echo -e "\nhttpd process run as" >>$RESULT_FILE
ps axu | grep httpd | grep -v '^root' >>$RESULT_FILE

#apache user shell should be invalid (pl.: /sbin/nologin, /dev/null)
echo -e "\nApache2 User shell:" >>$RESULT_FILE
egrep "www|apache" /etc/passwd | awk -F':' '{print$7}' >>$RESULT_FILE

#apache user lock
echo -e "\nApache2 User lock state:" >>$RESULT_FILE
sudo passwd -S $(egrep "www|apache" /etc/passwd | awk -F':' '{print$1}') >>$RESULT_FILE

#apache folder/file ownership check
APACHE_SERVED_FOLDER=$(grep -r -i -P "^[ ,'\t']*documentroot" /etc/apache2/ 2>/dev/null | egrep -v -i 'template|sample' | awk -F'DocumentRoot' '{print$2}' | sed 's/"//g' | tr -d ' ')
echo -e "\n--==Apache2 DocumentRoot permission checks==--" >>$RESULT_FILE
find $APACHE_SERVED_FOLDER \! -user root -ls >>$RESULT_FILE
find $APACHE_SERVED_FOLDER -path $APACHE_SERVED_FOLDER/htdocs -prune -o \! -group root -ls >>$RESULT_FILE
find -L $APACHE_SERVED_FOLDER \! -type l -perm /o=w -ls >>$RESULT_FILE
find $APACHE_SERVED_FOLDER -name CoreDumpDirectory -type d >>$RESULT_FILE
find -L $APACHE_SERVED_FOLDER \! -type l -perm /g=w -ls >>$RESULT_FILE
find -L $APACHE_SERVED_FOLDER -group $APACHE2_GROUP -perm /g=w -ls >>$RESULT_FILE

#Access control check
#Deny access to OS root dir
#config fileok beolvasása és a <Directory> és </Directory> részek között szöveg kimásolása
echo -e "\n--==Access Control check==--" >>$RESULT_FILE
echo -e "\nDirectory definitions:" >>$RESULT_FILE
perl -ne 'print if /^ *<Directory */i .. /<\/Directory/i' /etc/apache2/*.conf >>$RESULT_FILE
perl -ne 'print if /^ *<Directory */i .. /<\/Directory/i' /etc/apache2/vhosts.d/* >>$RESULT_FILE

#Listen directives
echo -e "\nListen directives:" >>$RESULT_FILE
grep -r -i -P "^[ ,'\t']*Listen" /etc/apache2/ 2>/dev/null | egrep -v -i 'template|sample' | perl -pe 's/[\t]+[ ]+//' >>$RESULT_FILE

#Logging
echo -e "\n--==Logging configuration==--" >>$RESULT_FILE
grep -E -r "^[A-Z]?LogLevel|^[A-Z]?ErrorLog|^[A-Z]?LogFormat|^[A-Z]?CustomLog" /etc/apache2/ | grep -E -v "template|sample" >>$RESULT_FILE

#SSL file permissions
echo -e "\n--==SSL key permissions==--" >>$RESULT_FILE
SSL_KEYFILE=$(grep -r -i -P "^[ \t]*sslcertificatekeyfile" /etc/apache2/ 2>/dev/null | awk -F'SSLCertificateKeyFile' '{print$2}' | tr -d ' ')
sudo stat $SSL_KEYFILE >>$RESULT_FILE

#Info leakage checks
echo -e "\n--==Info leakage checks==--" >>$RESULT_FILE
grep -r -i "servertokens" /etc/apache2/ >>$RESULT_FILE
grep -r -i "serversignature" /etc/apache2/ >>$RESULT_FILE
grep -r -i "keepalive" /etc/apache2/ >>$RESULT_FILE

#security framework checks
echo -e "\n--==OS security framework checks==--" >>$RESULT_FILE
rpm -qa | egrep 'selinux|apparmor' >>$RESULT_FILE
