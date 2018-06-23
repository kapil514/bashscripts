#!/bin/bash
#########################################################################
# rotateCatalinaLogs.sh                                                 #
#                                                                       #
# Author: Jason Svendsgaard 10/13/2009                                  #
#                                                                       #
# Rotates and archives Cataling Logs logs without sending the HUP signal #
#                                                                       #
#########################################################################
umask 022
#TIME_STAMP=$(date +"%Y-%m-%d_%H%M%S")
TIME_STAMP=$(date +"%Y-%m-%d")
LOG_LOC=/var/logs/tomcat/server
LOGFILE=catalina.out


for DIR in `/usr/bin/find $LOG_LOC/* -maxdepth 1 -type d`; do
   if [ -s "$DIR/$LOGFILE" ]; then
      /bin/cp -p $DIR/$LOGFILE $DIR/$LOGFILE.$TIME_STAMP
      /bin/cat /dev/null > $DIR/$LOGFILE
      /bin/gzip $DIR/$LOGFILE.$TIME_STAMP
   fi
done
   /usr/bin/find $LOG_LOC/* -mtime +15 -exec rm {} \;

## <Parvez> Delay of 2 mins is set bcos sometimes splunk does not get data if log is zero
#sleep 60
#/etc/init.d/rsyslog stop
#rm /opt/rsyslog/*.log > /dev/null 2>&1
#sleep 60
#/etc/init.d/rsyslog start

