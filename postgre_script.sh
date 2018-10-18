#!/bin/bash
TMP_RESULT_FILE=/tmp/pgfindings
echo -e "\nPostgreSQL service runlevel:">$TMP_RESULT_FILE
who -r >>$TMP_RESULT_FILE
echo -e "\nPostgreSQL user home dir structure (non-recursive):">>$TMP_RESULT_FILE
ls -la $HOME >>$TMP_RESULT_FILE

echo -e "\nPostgreSQL initialization logs">>$TMP_RESULT_FILE
cat $HOME/pgstartup.log >>$TMP_RESULT_FILE
cat $HOME/initlog >>$TMP_RESULT_FILE
echo -e "\nPostgreSQL data cluster directory permissions">>$TMP_RESULT_FILE
ls -la $HOME>>$TMP_RESULT_FILE

echo -e "\nPostgreSQL config files:" >>$TMP_RESULT_FILE
find $HOME -name *.conf 2>/dev/null 1>>$TMP_RESULT_FILE

echo -e "\nPostgreSQL config file stats:">>$TMP_RESULT_FILE
stat $HOME/data/*.conf >>$TMP_RESULT_FILE

echo -e "\nPostgreSQL user file permission mask">>$TMP_RESULT_FILE
umask >>$TMP_RESULT_FILE

log_dir=$(grep log_directory $HOME/data/postgresql.conf | awk -F' ' '{print$3}' | sed -e "s/'//g")
echo -e "\nPostgreSQL logging directory: $log_dir" >>$TMP_RESULT_FILE
echo -e "\nLog directory rwx permissions:" >>$TMP_RESULT_FILE
ls -la $HOME/data/$log_dir >>$TMP_RESULT_FILE


	echo -e "\nPostgreSQL settings, parameters:">>$TMP_RESULT_FILE
	echo -e "\n Listening port:" >>$TMP_RESULT_FILE
	psql -c "SHOW port" >>$TMP_RESULT_FILE
	echo -e "\n Object ownership:" >>$TMP_RESULT_FILE
	psql -x -c "\df+" >>$TMP_RESULT_FILE
	echo -e "\n psaudit package" >>$TMP_RESULT_FILE
	rpm -qa | grep psaudit >>$TMP_RESULT_FILE
	echo -e "\n Logging options:">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_destination">>$TMP_RESULT_FILE
	psql -x -c "SHOW logging_collector">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_directory">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_filename">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_file_mode">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_truncate_on_rotation">>$TMP_RESULT_FILE
	psql -x -c "SHOW debug_print_parse">>$TMP_RESULT_FILE
	psql -x -c "SHOW debug_print_rewritten">>$TMP_RESULT_FILE
	psql -x -c "SHOW debug_print_plan">>$TMP_RESULT_FILE
	psql -x -c "SHOW debug_pretty_print">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_checkpoints">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_connections">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_disconnections">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_duration">>$TMP_RESULT_FILE
	psql -x -c "SHOW log_temp_files">>$TMP_RESULT_FILE
	echo -e "\n PostgreSQL Audit extension check">>$TMP_RESULT_FILE
	psql -x -c "SHOW shared_preload_libraries">>$TMP_RESULT_FILE
	echo -e "\n Checking user roles" >>$TMP_RESULT_FILE
	psql -x -c "\du" >>$TMP_RESULT_FILE
	echo -e "\n Users:">>$TMP_RESULT_FILE
	psql -x -c "SELECT * from pg_user" >>$TMP_RESULT_FILE
	psql -x -c "SELECT usename, passwd FROM pg_shadow" >>$TMP_RESULT_FILE
	echo -e "\n Connection limits:">>$TMP_RESULT_FILE
	psql -x -c "SHOW max_connections" >>$TMP_RESULT_FILE
	psql -x -c "SELECT rolname,rolconnlimit FROM pg_authid" >>$TMP_RESULT_FILE
	echo -e "\n Privileged module execution:">>$TMP_RESULT_FILE
	psql -x -c "SELECT nspname, proname, proargtypes, prosecdef, rolname, proconfig FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid JOIN pg_authid a ON a.oid = p.proowner WHERE prosecdef OR NOT proconfig IS NULL" >>$TMP_RESULT_FILE

	echo -e "\n Build support configuration:">>$TMP_RESULT_FILE
#	/usr/pgsql-9.6/bin/pg_config --configure | grep "--with-openssl" >>$TMP_RESULT_FILE
	echo -e "\n Encryption settings from the runnig service:">>$TMP_RESULT_FILE
	psql -x -c "SHOW ssl">>$TMP_RESULT_FILE
	echo -e "\n Encryption settings from the config files:">>$TMP_RESULT_FILE
	grep ssl $HOME/data/postgresql.conf >>$TMP_RESULT_FILE
	echo -e "\n Checking FIPS enabled crypto:">>$TMP_RESULT_FILE
	cat /proc/sys/crypto/fips_enabled>>$TMP_RESULT_FILE
	openssl version>>$TMP_RESULT_FILE
	echo -e "\n PGCrypto extension check:">>$TMP_RESULT_FILE
	psql -x -c "SELECT * FROM pg_available_extensions WHERE name='pgcrypto'">>$TMP_RESULT_FILE

echo -e "\nAuthentication methods:" >>$TMP_RESULT_FILE
cat $HOME/data/pg_hba.conf >>$TMP_RESULT_FILE
