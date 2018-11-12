#!/bin/bash

today=$(date +"%Y-%m-%d")
workdir="$HOME/logmonitor"
logparse="$workdir/logparse"
logpath="/var/log/nginx"
scriptlog="$workdir/script.log"
mailtext="$workdir/mail.txt"

if [[ ! -d "$logparse" ]]; then
    mkdir -p $logparse
fi
    
# match access log file contents, igy mindig megvan a teljes lista, de csak egyszer
for i in $(ls -d -1 -t $logpath/access.log*);do
    zgrep -B 1 "GET /enyem[.]html" $i >> $logparse/logmatch-$today
done

# determine last two days' logmatch files
file1=$(ls -1t $logparse/ | head -n 1)
file2=$(ls -1t $logparse/ | head -n 2 | tail -n 1)

filediff=$(diff $logparse/$file1 $logparse/$file2)

# alert if any new matching lines are present
if [[ -z $filediff ]]; then
    echo "$today : file diff empty, no new matching lines" >> $scriptlog

# if new additional lines in the file diff output, then create and send mail
elif grep "^<" $filediff &>/dev/null; then
    echo "$today : new matching line, composing mail.txt ..." >> $scriptlog

    # compose mail
    echo "To:pentesters@govcert.hu" > $mailtext
    echo "From:account@domain.net" >> $mailtext
    echo "Subject: logmonitor alert" >> $mailtext
    echo "" >> $mailtext
    echo "New lines in the logs:"
    grep "^<" "$filediff" >> $mailtext
	
    # sendmail -t < $mailtext && echo "$today : mail sent" >> $scriptlog || echo "$today : mail command error" >> $scriptlog
    # TODO configure /etc/ssmtp/ssmtp.conf with mailserver data + account
    
# if the file diff output indicates that they do not match, then check if it is because of logrotation removing files from the logpath thus the todays $logparse file and yesterdays *.old file do not match
elif grep "^>" $filediff &>/dev/null; then  
    echo "$today : files don't match because the logrotation removed some lines since yesterday" >> $scriptlog
fi

# keep only the last logmatch file
rm $logparse/$file2
mv $logparse/$file1 $logparse/$file1.old
