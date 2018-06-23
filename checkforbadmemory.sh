#!/bin/sh
if [ ! -d /var/tmp/badmem ]; then
  mkdir /var/tmp/badmem
fi
cd /var/tmp/badmem
rm ./*.out ./all
touch all


SERVERS=$(/opt/totality/bby/bin/gethost -x kvm,ucs,vmw,ps,hpux,sun,vm,project,dell,windows | grep -v dlpolsdb | sort)

for i in $SERVERS; do
        (ssh -q $i '(echo -n "'$i' " ;echo -n `hpasmcli -s "show dimm" |egrep -i "Cartridge|module|Status" |egrep -B2 "degraded|failed|error"`)' 2>&1 &) > /var/tmp/badmem/$i.out
done

sleep 300
NOTRESPONDED=`ps -aef |grep hpasmcli |grep -v grep |awk '{print $10}'`
NOTRESPONDEDPID=`ps -aef |grep hpasmcli |grep -v grep |awk '{print $2}'`

for i in $NOTRESPONDED; do
        echo "$i never responded to the query" >> ./all
done

for k in "$NOTRESPONDEDPID"; do
        kill -9 $k
done

ERROR=`find . -name "*.out" -size 0 |awk -F/ '{print $2}' |awk -F. '{print $1}'`

for i in $ERROR; do
        echo "$i did not return any value" >> ./all
done

BROKENHPASMCLI=`egrep -h "not found" *.out |awk '{print $1}'`

for l in $BROKENHPASMCLI; do
        echo "$l has a broken or not existent hpasmcli" >> ./all
done

egrep -ih "[0-9] Status" *.out >> ./all
egrep -i [a-z] ./all 1> /dev/null

if [ "$?" = "0" ]; then
        cat ./all
fi
################################################################
