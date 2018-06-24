#!/bin/bash
servername=$1
if [ -z $1 ]
then
echo "Error : Server name not provided"
echo "Usage : $0 Servername"
exit 1
fi
while (true)
do
echo "##########################################################"
echo "Main Menu "
echo "1.check file system usage "
echo "2.check large file system for given file system "
echo "3.Connect to server " 
echo "4.Exit "
echo "#########################################################"
echo -n "Please enter your choice :   "
read option
case $option in
1) read -p "Enter file system name :" fs_name
ssh $1 "df -h $fs_name"
;;
2)echo "##############################################################"
echo "*********************************************************"
echo "##############################################################"
echo -n  "enter file system name to find the usage "
read fsname
echo "Enter the size of files which you want to search (Eg : 5M or 20M,1G)"
read fssize
ssh redhat2.station.com "find $fsname -xdev -size +$fssize -exec ls -ltr {} \; |more"
;;
3)echo "####### Connecting to server name #######"
ssh $1;exit 0

 ;;
4) exit 0
;;
*)echo "Enter valid option ";;
esac 
done
