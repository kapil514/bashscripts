#!/bin/sh
if [ ! -d /var/tmp/baddisk ]; then
  mkdir /var/tmp/baddisk
fi
cd /var/tmp/baddisk
rm ./*.out ./all
touch all

SERVERS=$(/opt/totality/bby/bin/gethost -x kvm,ucs,vmw,ps,hpux,sun,vm,project,dell,windows |grep -v dlpolsdb | sort)

for i in $SERVERS; do
(ssh -q $i '(echo -n "'$i' ";
host=`hostname|awk -F. "{print $1}"`
slot=`hpacucli ctrl all show detail |egrep "   Slot" |awk "{print \$NF}"`
baddrives=`
for i in $slot
do
        hpacucli ctrl slot=$i pd all show |egrep physicaldrive|egrep -wv OK
done`
if [ -z "$baddrives" ]
then
        echo -n "no bad drives were found."
        echo
        exit 0
else
echo -n "I found the following bad drive: "
echo -n $baddrives
echo
fi
)' &) > /var/tmp/baddisk/$i.out
done
sleep 300
NOTRESPONDED=$(ps -aef |grep -i "host=\`hostname" |grep -v grep |awk '{print $10}')
NOTRESPONDEDPID=$(ps -aef |grep -i "host=\`hostname" |grep -v grep |awk '{print $2}')
for i in $NOTRESPONDED
do
        echo "$i never responded to the query" >> ./all
done
ERROR=`find . -name "*.out" -size 0 |awk -F/ '{print $2}' |awk -F. '{print $1}'`
for i in $ERROR
do
        echo "$i did not return any value" >> ./all
done

for k in "$NOTRESPONDEDPID"
do
        kill -9 $k
done
grep -ih "[0-9] I found" *.out >> ./all
egrep -i [a-z] ./all 1> /dev/null
if [ "$?" = "0" ]
then
        cat ./all
fi
