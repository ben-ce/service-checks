#!/bin/bash

today=`date +"%Y-%m-%d"`
logparse="$HOME/logparse"
logpath='/var/log/nginx'

mail_command(){
	/usr/sbin/sendmail -t < mail.txt
}

# match access log file contents, igy mindig megvan a teljes lista, de csak egyszer
for i in $(ls -d -1 -t $logpath/access.log*);do
	zgrep -B 1 "GET /enyem[.]html" $i >> $logparse/logmatch-$today
done

# determine last two days' logmatch files
file1=$(ls -1t $logparse/ | head -n 1)
file2=$(ls -1t $logparse/ | head -n 2 | tail -n 1)

filediff=$(diff $logparse/$file1 $logdir/$file2)

# alert if any new matching lines are present
if [[ -z $filediff ]]; then
	echo "file diff empty, no new matching lines"
else 
	echo "if statement not true"
	
	# compose mail
	echo "To:pentesters@govcert.hu" > mail.txt
	echo "From:account@domain.net" >> mail.txt
	echo "Subject: logmonitor alert" >> mail.txt
	echo "" >> mail.txt
	echo "$filediff" >> mail.txt
	# mail_command() # TODO define mail_command function
fi

# keep only the last logmatch file
rm $logparse/$file2
mv $logparse/$file1 $logdir/$file1.old
