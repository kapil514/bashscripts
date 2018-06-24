#!/bin/bash 
#echo "Hello "
echo "Connecting to $1"
serverid=$1
cpw=ciuser
if [ ! -z "$serverid" ]
then
sshpass -p $cpw ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -l ciuser chsnmvproc$serverid.usdc2.oraclecloud.com
else
echo "provide valid server id Eg; 12vm1 or 5vm3" 
fi
