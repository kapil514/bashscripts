#!/bin/sh
#######################################################################
# Created By Parvez Hussain
# Created Date: 02/28/2009
# Modified Date: 06/28/2011
# Modified Date: 10/01/2013
#  Subject: This script is to clear diskspace on the filesystem
# Author:  Parvez Hussain <parvez.hussain@verizonbusiness.com> for Verizon Business
#
#       Copyright: This document and the information within is confidential and proprietary to Verizon Business.
#       Any distribution of this document or of the information within, without prior written authorization
#       from Verizon Business is strictly prohibited.  In addition, any unauthorized distribution will
#       harm Verizon Business and will be deemed a direct breach of Verizon Business's intellectual property rights.
######################################################################

HOST=$(hostname)
DATE=$(date +%d%b%Y_%H%M)
#NOW=$(date +%b%y)

LOGDIR=/opt/logs

ATGBUILDDIR=/opt/webcontent/release
ATGCODEPATH=/opt/atg
ATGAPPLOG=/var/logs/jboss/server
ATGWEBLOG=/var/logs/apache/$HOST
SRCHAPPLOG=/var/logs/sptadm/server
APPLOG=/var/logs/*/server

DEPLOYAUDITDIR=$ATGAPPLOG/AUDIT
AUDITLOG=$DEPLOYAUDITDIR/CleanFileSystem_${HOST}_${DATE}.log

FASTLOG=/var/logs/fastadm/server/log
FASTEXLTBKP=/var/fast/olsexport/data/backup

IBMDIR=/opt/IBM
IBMLOGDIR=/opt/logs/ibm/was6.1

THRESHOLD=80
FLAG=y
FSNFLAG=0

HOSTTYPE=$(uname -a | awk '{print $1}')
if [ "$HOSTTYPE" = "Linux" ]; then
        DSKCMD='df -k'
else
        DSKCMD=bdf
fi

# find /var/logs/*/server/* -mtime +15 -type f -exec rm {} \;
# find /var/logs/*/server/* -type f \( -name "*.log.*" -o -name "*.out.*" \) -a  ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec /bin/gzip {} \;
# find /opt/webcontent/release/* \( -type f -o -type d \) -maxdepth 1  -mtime +30 \( -name  "batch*" -o -name  "DotCom*" -o -name "Best*" \) -exec ls -ld {} \;


########################## TMP FOLDER #######################################

TMP() {

FLAGTMP=y

if [ "$FSN" = "/tmp" ]; then

   DSKSPC=$($DSKCMD /tmp | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

        echo -e "\n*****************************************************"
        echo -e "\n$DATE $HOST /tmp $DSKSPC"
        echo
        $DSKCMD /tmp
        echo "Deleting files that are 60 days old..."
        find /tmp -type f -mtime +60 -exec ls -l {} \;
        find /tmp -type f -mtime +60 -exec rm -rf {} \;
        echo "Deleting files that are 30 days old and more that 1MB files..."
        find /tmp -type f -mtime +30 -size +1000000c -exec ls -l {} \;
        find /tmp -type f -mtime +30 -size +1000000c -exec rm -rf {} \;
        $DSKCMD /tmp
   fi

   DSKSPC=$($DSKCMD /tmp | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD /tmp
        echo -e "\n\n$HOST:Manual Intervention is Required"
        echo -e "$HOST: /tmp Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST: /tmp Displaying top 30 large files and folders \n"
        du -akx /tmp | sort -nr | head -30
   else
        FLAGTMP=n
   fi

   echo -e "\nCurrent Used Diskspace for /tmp is ${DSKSPC}% \n"
else
        FLAGTMP=n
fi
}

########################## VAR FOLDER #######################################

VAR() {

FLAGVAR=y

if [ "$FSN" = "/var" ]; then

   DSKSPC=$($DSKCMD /var | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

        echo -e "\n*****************************************************"
        echo -e "\n$DATE $HOST /var $DSKSPC"
        echo
        $DSKCMD /var
        echo "Looking for large maillog backup files and nullifying them.."
        ls -l /var/log/maillog.*
        echo -e " - rm -rf /var/log/maillog.*.gz"
        rm -rf /var/log/maillog.*.gz
                echo -e " - cat /dev/null > /var/log/maillog.1"
        cat /dev/null > /var/log/maillog.1
        echo -e "- cat /dev/null > /var/log/maillog.2"
        cat /dev/null > /var/log/maillog.2
        echo -e "- cat /dev/null > /var/log/maillog.3"
        cat /dev/null > /var/log/maillog.3
        echo -e "- cat /dev/null > /var/log/maillog.4"
        cat /dev/null > /var/log/maillog.4

                if [ -d /var/log/scsplog ]; then
                        echo -e "Deleteing 30 days old logs from /var/log/scsplog"
                        find /var/log/scsplog/* -type f -name "*.csv"  -mtime +30 -exec rm {} \;
                fi

        $DSKCMD /var
   fi

   DSKSPC=$($DSKCMD /var | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD /var
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:/var Filesystem cleanup FAILED!!!\n"
      echo -e "$HOST: /var Displaying top 30 large files and folders \n"
      du -axk /var | sort -nr | head -30
   else
        FLAGVAR=n
   fi

   echo -e "\nCurrent Used Diskspace for /var is ${DSKSPC}% \n"
else
        FLAGVAR=n
fi

}



########################### ATG WEB LOG ######################################
ATGWebLog() {

FLAGATGWEBLOG=y

if [ "$FSN" = "/opt/logs" -o "$FSN" = "/var/logs" ]; then

        $DSKCMD $ATGWEBLOG
        echo -e "\n Deleting files under $ATGWEBLOG that are 7 days old"
        find $ATGWEBLOG/*.bestbuy.com*/* -type f -mtime +7 -exec ls -ltr {} \;
        find $ATGWEBLOG/*.bestbuy.com*/ -type f -mtime +7 -exec rm {} \; > /dev/null 2>&1
         if [ "$(echo $HOST | grep dlp)" ];then
             echo -e "\n Zipping Files that are more than 3 days old"
             echo -e "- find $ATGWEBLOG/*.bestbuy.com*/ -type f -mtime +3 | egrep -v \".gz|.zip\" | xargs /bin/gzip"
             find $ATGWEBLOG/*.bestbuy.com*/ -type f -mtime +3 | egrep -v ".gz$|.zip$" | xargs /bin/gzip > /dev/null 2>&1
        else
             echo -e "\n Deleting files under $ATGWEBLOG that are more than 3 days old"
             echo -e "- find $ATGWEBLOG/*.bestbuy.com*/ -type f -mtime +3 exec rm {} \;"
             find $ATGWEBLOG/*.bestbuy.com*/ -type f -mtime +3 -exec rm {} \; > /dev/null 2>&1
        fi

   DSKSPC=$($DSKCMD $ATGWEBLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD $ATGWEBLOG
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:$ATGWEBLOG Filesystem cleanup FAILED!!!\n"
      echo -e "$HOST:$ATGWEBLOG Displaying top 30 large files and folders \n"
      du -axk /opt/logs/* | sort -nr | head -30
   else
      FLAGATGWEBLOG=n
   fi
   echo -e "\nCurrent Used Diskspace for $ATGWEBLOG is ${DSKSPC}% \n"

else
   FLAGATGWEBLOG=n
fi
}


########################### GENERIC APP LOG ######################################

AppLog() {

FLAGAPPLOG=y

if [ "$FSN" = "/opt/logs" -o "$FSN" = "/var/logs" -o "$FSN" = "/var" ]; then

   DSKSPC=$($DSKCMD $APPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

      $DSKCMD $APPLOG

      echo -e "\n Deleting files under $APPLOG that are 7 days old"
      echo -e "\n The below files will be deleted........"
      find $APPLOG/* -mtime +7 -type f -exec ls -ltr {} \;
      echo -e "\n\n- find $APPLOG/* -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1"
      find $APPLOG/* -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1

      if [ "$(echo $HOST | grep dlp)" ];then
        echo -e "\n Zipping Files that are more than 3 days old"
        echo -e "- find $APPLOG/* -type f \( -name "*.log.*" -o -name "*.out.*" \) -a  ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec /bin/gzip {} \;"
        find $APPLOG/* -type f \( -name "*.log.*" -o -name "*.out.*" \) -a  ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec /bin/gzip {} \; > /dev/null 2>&1
      else
        echo -e "\n Deleting files under $APPLOG that are more than 3 days old"
        echo -e "- find $APPLOG/* -mtime +3 -type f -exec rm {} \;"
        find $APPLOG/* -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1
      fi

   fi

      DSKSPC=$($DSKCMD $APPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

      if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD $APPLOG
            if [ ! "$(echo $HOST | grep dlp)" ];then
                echo "Nullifying large log files..."
                du -ak $APPLOG/*| sort -nr | egrep "\.log$|\.out$" | head -5 | awk '{print $NF}' | xargs ls -l
                LARGEFILES=$(du -ak $APPLOG/*| sort -nr | egrep "\.log$|\.out$" | head -5 | awk '{print $NF}')
                for FILE in $LARGEFILES; do
                        echo "Nullifying log file $FILE ..."
                        cat /dev/null > $FILE
                done
            fi
     fi

   DSKSPC=$($DSKCMD $APPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD $APPLOG
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:$APPLOG Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST:$APPLOG Displaying top 30 large files and folders \n"
      du -axk $APPLOG | sort -nr | head -30
   else
        FLAGAPPLOG=n
   fi

   echo -e "\nCurrent Used Diskspace for $ATGAPPLOG is ${DSKSPC}% \n"

else
   FLAGAPPLOG=n
fi

}


########################### ATG APP LOG ######################################

ATGAppLog() {

FLAGATGAPPLOG=y

if [ "$FSN" = "/opt/logs" -o "$FSN" = "/var/logs" ]; then

   DSKSPC=$($DSKCMD $ATGAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

      $DSKCMD $ATGAPPLOG

#### TO BE REMOVED AFTER THE BUG IS FIXED
      echo "Nullifying large logs due to the bug"
      find /var/logs/jboss/server/bb*/error.log -xdev  -exec cp /dev/null  {} \; > /dev/null 2>&1
      find /var/logs/jboss/server/bb*/*2014* | egrep -v ".gz$|.zip$" |xargs /bin/gzip > /dev/null 2>&1
 ############################################

      echo "Deleting archive files..."
      echo "- rm -rf $ATGAPPLOG/*/archives/*"
      rm -rf $ATGAPPLOG/*/archives/*

      echo -e "\n Deleting files under $ATGAPPLOG that are 7 days old"
      echo -e "- find $ATGAPPLOG/bb*/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1"
      find $ATGAPPLOG/bb*/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1
      echo -e "- find $ATGAPPLOG/AUDIT/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1"
      find $ATGAPPLOG/AUDIT/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1

      if [ "$(echo $HOST | grep dlp)" ];then
        echo -e "\n Zipping Files that are more than 3 days old"
        echo -e "- find $ATGAPPLOG/bb*/ -type f -mtime +3 | egrep -v \".gz|.zip\" | xargs /bin/gzip"
        find $ATGAPPLOG/bb*/ -type f -mtime +3 | egrep -v ".gz$|.zip$" | xargs /bin/gzip > /dev/null 2>&1
      else
        echo -e "\n Deleting files under $ATGAPPLOG that are more than 3 days old"
        echo -e "- find $ATGAPPLOG/bb*/ -mtime +3 -type f -exec rm {} \;"
        find $ATGAPPLOG/bb*/ -mtime +3 -type f -exec rm {} \; > /dev/null 2>&1
      fi

   fi

      DSKSPC=$($DSKCMD $ATGAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

      if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD $ATGAPPLOG
            if [ ! "$(echo $HOST | grep dlp)" ];then
                echo "Nullifying large log files..."
                du -ak $ATGAPPLOG/*| sort -nr | grep "\.log$" | head -5 | awk '{print $NF}' | xargs ls -l
                LARGEFILES=$(du -ak $ATGAPPLOG/*| sort -nr | grep "\.log$" | head -5 | awk '{print $NF}')
                for FILE in $LARGEFILES; do
                        echo "Nullifying log file $FILE ..."
                        cat /dev/null > $FILE
                done
            fi
     fi

   DSKSPC=$($DSKCMD $ATGAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD $ATGAPPLOG
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:$ATGAPPLOG Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST:$ATGAPPLOG Displaying top 30 large files and folders \n"
      du -axk /opt/logs/* | sort -nr | head -30
   else
        FLAGATGAPPLOG=n
   fi

   echo -e "\nCurrent Used Diskspace for $ATGAPPLOG is ${DSKSPC}% \n"

else
   FLAGATGAPPLOG=n
fi

}


##################### ATG BUILD FOLDER ######################################

AtgBuildDir() {

FLAGATGBLD=y

if [ "$FSN" = "/opt/webcontent" ]; then

   DSKSPC=$($DSKCMD $ATGBUILDDIR | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

        echo -e "\n*****************************************************"
        echo -e "$DATE $HOST $ATGBUILDDIR\n"
        $DSKCMD $ATGBUILDDIR
        echo
     case $HOST in
        dlq*|dlc* )
                WEBCONTENTDIR=/opt/webcontent/*
                ;;
        * )
                WEBCONTENTDIR=/opt/webcontent
                ;;
     esac

     COUNT=0
     while [ "$DSKSPC" -gt "$THRESHOLD" -a $COUNT -le 5 ];do
        COUNT=`expr $COUNT + 1`
        BUILDCOUNT=`expr $(ls -ltr $ATGBUILDDIR | grep " BestBuy" | wc -l) / 2`
        BUILDCODE=$(ls -ltr $ATGBUILDDIR | egrep  "BestBuy|DotCom" | awk '{print $NF}' | head -${BUILDCOUNT})
        echo -e "\n$HOST:Build Code identified to be deleted"
        echo -e $BUILDCODE

        LIVECODE=$(ls -l /opt/jboss/server/bb*/deploy | grep BestBuy | awk -F"/" '{print $5}' | sort | uniq)
        LIVECODE=$(echo -e $LIVECODE |sed 's/ /|/g')
        echo -e "\n$HOST:$LIVECODE  Current Live code"

        echo -e "\n$HOST:Ignoring LiveCode from identified BuildCode"
        for CODE in $BUILDCODE; do
                echo -e $CODE | egrep -v $LIVECODE
                if [ $? -eq 0 ];then
                        echo -e $CODE >> $ATGBUILDDIR/delcode
                fi
        done
        if [ -s $ATGBUILDDIR/delcode ]; then
                for CODE in $(cat $ATGBUILDDIR/delcode); do
                        echo -e "\n$HOST:Deleting $CODE and its related Data and content"
                        echo -e "- rm -rf $ATGBUILDDIR/*${CODE}*"
                        rm -rf $ATGBUILDDIR/*${CODE}*
                        echo -e "- rm -rf $DEPLOYAUDITDIR/*${CODE}*"
                        rm -rf $DEPLOYAUDITDIR/*${CODE}*
                done
        fi
        rm $ATGBUILDDIR/delcode > /dev/null 2>&1
        echo -e
        $DSKCMD $ATGBUILDDIR
        DSKSPC=$($DSKCMD $ATGBUILDDIR | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
     done

        rm -rf  /opt/webcontent/release/delcode >  /dev/null 2>&1
   fi

   DSKSPC=$($DSKCMD $ATGBUILDDIR | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD $ATGBUILDDIR
        echo -e "\n\n$HOST:Manual Intervention is Required"
        echo -e "$HOST:$ATGBUILDDIR Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST:$ATGBUILDDIR Displaying top 30 large files and folders \n"
        du -axk $ATGBUILDDIR/* | sort -nr | head -30
   else
       FLAGATGBLD=n
   fi

echo -e "\nCurrent Used Diskspace for $ATGAPPLOG is ${DSKSPC}% \n"

else
   FLAGATGBLD=n
fi

}



########################### FAST LOG ######################################

FastLog() {

FLAGFASTLOG=y

if [ "$FSN" = "/opt/logs" -o "$FSN" = "/var/logs" -o "$FSN" = "/var/logs/fastadm" ]; then

   DSKSPC=$($DSKCMD $FASTLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

      $DSKCMD $FASTLOG

      echo "Deleting all gz files that are 15 days old..."
      echo "- find $FASTLOG/* -type f -iname "*.gz" -mtime +15 -exec rm {} \;"
      find $FASTLOG/* -type f -iname "*.gz" -mtime +15 -exec rm {} \; > /dev/null 2>&1

       if [ "$(echo $HOST | grep dlp)" ];then
          echo "Zipping all 'scrap.* files that are 3 days old..."
          echo "- find $FASTLOG/* -type f \( -name "*.scrap.*" \) -a ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec /bin/gzip {} \;"
          find $FASTLOG/* -type f \( -name "*.scrap.*" \) -a ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec /bin/gzip {} \; > /dev/null 2>&1
      else
         echo -e "\n Deleting files of type "*.scrap.*" that are more than 3 days old"
         echo -e "- find $FASTLOG/* -type f \( -name "*.scrap.*" \) -a ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec rm {} \;"
         find $FASTLOG/* -type f \( -name "*.scrap.*" \) -a ! \( -iname "*.gz" -o -name "*.zip" \) -mtime +3 -exec rm {} \;  > /dev/null 2>&1
      fi

   fi

   DSKSPC=$($DSKCMD $FASTLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

      if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD $FASTLOG
            if [ ! "$(echo $HOST | grep dlp)" ];then
                echo "Nullifying large log files..."
                du -ak $FASTLOG/*| sort -nr | egrep "\.scrap$" | head -5 | awk '{print $NF}' | xargs ls -l
                LARGEFILES=$(du -ak $FASTLOG/*| sort -nr | egrep "\.scrap$" | head -5 | awk '{print $NF}')
                for FILE in $LARGEFILES; do
                        echo "Nullifying log file $FILE ..."
                        cat /dev/null > $FILE
                        ls -l $FILE
                done
            fi
     fi

   DSKSPC=$($DSKCMD $FASTLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD $FASTLOG
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:$ATGAPPLOG Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST:$ATGAPPLOG Displaying top 30 large files and folders \n"
      du -axk $FASTLOG/* | sort -nr | head -30
   else
        FLAGFASTLOG=n
   fi

   echo -e "\nCurrent Used Diskspace for $ATGAPPLOG is ${DSKSPC}% \n"

else
   FLAGFASTLOG=n
fi

}


########################### SRCH APP LOG ######################################

SRCHAppLog() {

FLAGSRCHAPPLOG=y

if [ "$FSN" = "/opt/logs" -o "$FSN" = "/var/logs" ]; then

   DSKSPC=$($DSKCMD $SRCHAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')
   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then

      $DSKCMD $SRCHAPPLOG

      echo "Deleting archive files..."
      echo "- rm -rf $SRCHAPPLOG/*/archives/*"
      rm -rf $SRCHAPPLOG/*/archives/*
      echo "- rm -rf $SRCHAPPLOG/*/daas/archives/*"
      rm -rf $SRCHAPPLOG/*/daas/archives/*
      echo "- rm -rf $SRCHAPPLOG/*/saas/archives/*"
      rm -rf $SRCHAPPLOG/*/saas/archives/*

      echo -e "\n Deleting files under $SRCHAPPLOG that are 7 days old"
      echo -e "- find $SRCHAPPLOG/src*/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1"
      find $SRCHAPPLOG/src*/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1
      echo -e "- find $SRCHAPPLOG/AUDIT/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1"
      find $SRCHAPPLOG/AUDIT/ -mtime +7 -type f -exec rm {} \; > /dev/null 2>&1

      if [ "$(echo $HOST | grep dlp)" ];then
        echo -e "\n Zipping Files that are more than 3 days old"
        echo -e "- find $SRCHAPPLOG/src*/ -type f -mtime +3 | egrep -v \".gz|.zip\" | xargs /bin/gzip"
        find $SRCHAPPLOG/src*/ -type f -mtime +3 | egrep -v ".gz$|.zip$" | xargs /bin/gzip > /dev/null 2>&1
      else
        echo -e "\n Deleting files under $SRCHAPPLOG that are more than 3 days old"
        echo -e "- find $SRCHAPPLOG/src*/ -mtime +3 -type f -exec rm {} \;"
        find $SRCHAPPLOG/src*/ -mtime +3 -type f -exec rm {} \; > /dev/null 2>&1
      fi

   fi

      DSKSPC=$($DSKCMD $SRCHAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

      if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
        $DSKCMD $SRCHAPPLOG
            if [ ! "$(echo $HOST | grep dlp)" ];then
                echo "Nullifying large log files..."
                du -ak $SRCHAPPLOG/*| sort -nr | grep "\.log$" | head -5 | awk '{print $NF}' | xargs ls -l
                LARGEFILES=$(du -ak $SRCHAPPLOG/*| sort -nr | grep "\.log$" | head -5 | awk '{print $NF}')
                for FILE in $LARGEFILES; do
                        echo "Nullifying log file $FILE ..."
                        cat /dev/null > $FILE
                done
            fi
     fi

   DSKSPC=$($DSKCMD $SRCHAPPLOG | tail -1 | awk '{print $(NF-1)}' | sed '$s/.$//')

   if [ "$DSKSPC" -gt "$THRESHOLD" ]; then
      $DSKCMD $SRCHAPPLOG
      echo -e "\n\n$HOST:Manual Intervention is Required"
      echo -e "$HOST:$SRCHAPPLOG Filesystem cleanup FAILED!!!\n"
        echo -e "$HOST:$SRCHAPPLOG Displaying top 30 large files and folders \n"
      du -axk /opt/logs/* | sort -nr | head -30
   else
        FLAGSRCHAPPLOG=n
   fi

   echo -e "\nCurrent Used Diskspace for $SRCHAPPLOG is ${DSKSPC}% \n"

else
   FLAGSRCHAPPLOG=n
fi

}

######################### MAIN ###########################################
#(
#urldecode() { perl -MURI::Escape -le "print uri_unescape('${1//\'}')"; }
urldecode() { echo $1 | sed -e 's,%2F,/,g'; }
. $(dirname $0)/oofilter.args
FILE_SYSTEM=$MSG_TXT_1
echo "MESSAGE_TXT=$MSG_TXT_1"

df -k ${MSG_TXT_1} | egrep '[0-9]\%' | awk '{printf ("%s-%s\n",$(NF-1),$NF)}'| sed 's/%//' > /tmp/tmpfile

for FS in $(cat /tmp/tmpfile); do

    FSZ=$(echo $FS | awk -F"-" '{print $1}')
    FSN=$(echo $FS | awk -F"-" '{print $NF}')

    if [ "$FSZ" -gt "$THRESHOLD" ]; then
#       echo $FSN | egrep "/opt/logs$|/var/logs$|/tmp$|/opt/webcontent$|/opt/yantra$|/opt/IBM$|/var$" > /dev/null 2>&1
#       if [ $? -eq 0 ]; then
#               echo -e "$FSN : Attempting to clean up\n"

                case $HOST in
                        *[oa][lf][sp]db*)
                                echo $FSN | egrep "/tmp$|/var$" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                TMP
                                VAR
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;
                        *web*|*img*)
                                echo $FSN | egrep "/tmp$|/var$|/opt/logs$|/var/logs$" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                TMP
                                VAR
                                ATGWebLog
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" -a "$FLAGATGWEBLOG" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;
                        *[ackiomp][dlfpsu][iksprtx]app*)
                                echo $FSN | egrep "/tmp$|/var$|/opt/logs$|/var/logs$|/opt/webcontent$" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                TMP
                                VAR
                                ATGAppLog
                                AtgBuildDir
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" -a "$FLAGATGAPPLOG" = "n" -a "$FLAGATGBLD" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;
                        *src*)
                                echo $FSN | egrep "/tmp$|/var$|/opt/logs$|/var/logs$|$FASTLOG" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                TMP
                                VAR
                                SRCHAppLog
                                FastLog
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" -a "$FLAGSRCHAPPLOG" = "n" -a "$FLAGFASTLOG" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;

                        dlqolsbch01|*jmp*)
                                echo $FSN | egrep "/tmp$|/var$|/opt/logs$|/var/logs$|/opt/webcontent$" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                TMP
                                VAR
                                ATGAppLog
                                AtgBuildDir
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" -a "$FLAGATGAPPLOG" = "n" -a "$FLAGATGBLD" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;

                              *)
                                echo $FSN | egrep "/tmp$|/var$" > /dev/null 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "$FSN : Attempting to clean up\n"
                                else
                                    echo -e "$FSN : is above threshold and NOT part of Auto-Cleanup activity\n"
                                    FSNFLAG=$(expr $FSNFLAG + 1)
                                fi
                                AppLog
                                TMP
                                VAR
                                if [ "$FLAGTMP" = "n" -a "$FLAGVAR" = "n" -a "$FLAGAPPLOG" = "n" ]; then
                                    FLAG=n
                                fi
                                ;;
                esac
   fi
done

if [ "$FLAG" = "n" -a "$FSNFLAG" -eq 0 ]; then
        exit 0
else
        if [ "$FSNFLAG" -gt 0 ]; then
                echo -e "$FSNFLAG of the filesystems are above threshold and NOT part of Auto-Cleanup Activity."
        fi
        exit 1
fi
