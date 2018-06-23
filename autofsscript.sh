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
[root@redhat2 ~]# 
