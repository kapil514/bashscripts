#!/bin/sh
#######################################################################
# Created By Harekrishna Rao
# Created Date: 12/19/2013
# Subject: Check for bad Power Supply Units on HP servers
# Author:  Harekrishna Rao <harekrishna.rao@intl.verizon.com> for Verizon Business
#
######################################################################

PROGRAM=$0
HOST=$(hostname)
ALLOUTPUT=/var/tmp/psu.all
FAILEDPSU=/var/tmp/psu.failed
FAILEDTMP=/var/tmp/psu.tmp
NO_OUTPUT=/var/tmp/psu.nooutput
MAILFILE=/var/tmp/psu.mail
> $ALLOUTPUT
> $FAILEDPSU
> $FAILEDTMP
> $NO_OUTPUT
> $MAILFILE

echo -e "\nScript executed $HOST:$PROGRAM" >> $FAILEDTMP
echo -e "==================================================" >> $FAILEDTMP
echo -e "==================================================\n" >> $FAILEDTMP

SERVERS=$(/opt/totality/bby/bin/gethost -x kvm,ucs,vmw,ps,hpux,sun,vm,project,dell,winodws,BL460c,BL680c,BL685c | sort | grep -v dlpolsdb1)
#SERVERS="dlqsrcapp304 dlsnavapp01 dlsnavapp02 dlsnavapp03 dlsolsdb01"

for server in $SERVERS; do
    > /var/tmp/psu.server
    ssh -q $server "hpasmcli -s 'show powersupply'| grep Condition" > /var/tmp/psu.server
    if [ -s /var/tmp/psu.server ]; then
       sed -e "s/^/$server: /g" /var/tmp/psu.server | tee -a $ALLOUTPUT
    else
       echo "$server" | tee -a $ALLOUTPUT
    fi
done

cat $ALLOUTPUT | grep FAILED > $FAILEDPSU
if [ -s "$FAILEDPSU" ]; then
   cat $FAILEDTMP >> $MAILFILE
   cat $FAILEDPSU >> $MAILFILE
fi

cat $ALLOUTPUT | grep -v Condition  > ${NO_OUTPUT}
if [ -s "${NO_OUTPUT}" ]; then
   if [ ! -s "$MAILFILE" ]; then
      cat $FAILEDTMP >> $MAILFILE
   fi
(echo -e "\n\nThe following servers did not return correct value\n"
   for server in `cat ${NO_OUTPUT}`; do
        echo "=========================="
        echo $server
         ssh -q $server "hpasmcli -s 'show powersupply' "
   done
) >>  $MAILFILE
fi


if [ -s "$MAILFILE" ]; then
#cat $MAILFILE |/opt/totality/bin/mutt -s "Failed Power Supply Report" harekrishna.rao@intl.verizon.com
# cat $MAILFILE |/opt/totality/bin/mutt -s "Failed Power Supply Report" parvez.hussain@verizon.com
cat $MAILFILE |/opt/totality/bin/mutt -s "Failed Power Supply Report" bbyces@lists.verizonbusiness.com bbycxs@lists.verizonbusiness.com
fi
################################################################

 cat /opt/totality/bby/bin/check_ntp.sh
#!/bin/bash
#
# Quick simple script to check ntp status -- Howard Herring ACE

cat /dev/null > /tmp/check_ntp1.txt
cat /dev/null > /tmp/check_ntp2.txt
for server in $(gethost -L); do echo -n "$server ";ssh -q -o 'ConnectTimeout 5' $server 'ntpstat'|grep synchronised; done >> /tmp/check_ntp1.txt
grep unsynchronised /tmp/check_ntp1.txt > /tmp/check_ntp2.txt

if [ -s /tmp/check_ntp2.txt ] ; then
   mail -s "Check NTP Script found errors!" bbyces@lists.verizonbusiness.com -- -r "check_ntp@bestbuy.com" < /tmp/check_ntp2.txt
fi
