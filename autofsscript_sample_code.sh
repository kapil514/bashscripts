##################
########
#####
###
Script for housekeeping the file system files which are older than 5 days.
############
############
Created by Kapil Chowhan
#################
#!/bin/bash
PATH=/var/log
cd=$PATH
find . -mtime +5 -type -exec lsof {} \; > file.txt
find . -mtime +5 -type -f | xargs ls -ltr | awk '{print "./"$9}' >>file.txt

##Cronjob for zipping logs
##15 01 * * * find /var/logs/tomcat/`hostname`/bbchkp-app* -name "cto-agg-application.log.*" -type f -mtime +5 -exec rm {} \;;find /var/logs/tomcat/`hostname`/bbchkp-app* -name "cto-agg-application.log.*" -a  ! \( -iname "*.gz" -o -name "*.zip" \) -type f -mtime +1 -exec /bin/gzip -9f {} \;
