#!/bin/sh
#######################################################################
# Modified Date:
# Modified Date:
#  Subject: Check for bad battery in the controller
#
######################################################################


PROGRAM=$0
HOST=$(hostname)
ALLOUTPUT=/var/tmp/battery.all
FAILEDOUTPUT=/var/tmp/battery.failed
FAILEDTMP=/var/tmp/battery.tmp

echo -e "\t\t\n==================================================" > $FAILEDTMP
echo -e "\t\t\nScript executed $HOST:$PROGRAM" >> $FAILEDTMP

cat <<HERE >> $FAILEDTMP

if you see any ERROR in this report
        For Example " command not found"
                        "libXX.so  missing"

Fix PSP/SPP on the server that showing up the error
==================================================

HERE

SERVERS=$(/opt/totality/bby/bin/gethost -x kvm,ucs,vmw,ps,hpux,sun,vm,project,dell,windows | sort | grep -v dlpolsdb1)
(for server in $SERVERS; do
        echo -e "$server \c: "
        ssh -q $server  "hpacucli ctrl all show status | egrep "Battery";\
                         echo -ne "$server";hpacucli ctrl all show status | egrep "Controller";\
                         echo -ne "$server"; hpacucli ctrl all show status | egrep "Cache""

done) 2>&1 | tee $ALLOUTPUT

cat $ALLOUTPUT | grep -v OK |grep -v INFO > $FAILEDOUTPUT
#cat $ALLOUTPUT | egrep -i -B 2 "Failed" > $FAILEDOUTPUT

if [ -s "$FAILEDOUTPUT" ]; then
cat $FAILEDOUTPUT >> $FAILEDTMP
cat $FAILEDTMP |/opt/totality/bin/mutt -s "FAILED Batteries/Capacitors/Controller/Cache Report" email1@domain.com email12@domain.com 
#cat $FAILEDTMP |/opt/totality/bin/mutt -s "FAILED Batteries/Capacitors/Controller/Cache Report" emailid@domain.com
fi
