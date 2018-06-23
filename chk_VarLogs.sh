#!/bin/sh

>/var/logs/above90
>/var/logs/above80
>/var/logs/above70
>/var/logs/above60
for server in $(/opt/totality/bby/bin/gethost prod); do
STATUS=$(ssh -q $server "df -k /var/logs | grep /var/logs")
#STATUS=$(df -k /var/logs | grep /var/logs)
#echo $STATUS
#SIZE=$(echo $STATUS | awk '{print $(NF-1)}' | sed 's|%||g')
if [ "$STATUS" = "" ]; then
   SIZE=0
else
   SIZE=$(echo $STATUS | awk '{print $(NF-1)}' | sed 's|%||g')
fi
#echo $SIZE
if [ $SIZE -ge 90 ]; then
 echo "$server -- /var/logs -- ${SIZE}%" >> /var/logs/above90
elif [ $SIZE -ge 80 ]; then
 echo "$server -- /var/logs -- ${SIZE}%" >> /var/logs/above80
elif [ $SIZE -ge 70 ]; then
 echo "$server -- /var/logs -- ${SIZE}%" >> /var/logs/above70
elif [ $SIZE -ge 60 ]; then
 echo "$server -- /var/logs -- ${SIZE}%" >> /var/logs/above60
 fi
# read
 done

 if [ -s /var/logs/above90 ]; then
        echo -e "\n\nFileSystem above 90%"
        echo "--------------------"
        cat /var/logs/above90
fi
 if [ -s /var/logs/above80 ]; then
        echo -e "\n\nFileSystem above 80%"
        echo "--------------------"
        cat /var/logs/above80
fi
 if [ -s /var/logs/above70 ]; then
        echo -e "\n\nFileSystem above 70%"
        echo "--------------------"
        cat /var/logs/above70
fi
 if [ -s /var/logs/above60 ]; then
        echo -e "\n\nFileSystem above 60%"
        echo "--------------------"
        cat /var/logs/above60
fi
