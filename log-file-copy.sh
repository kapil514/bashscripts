#!/bin/bash
[ -d "/data/historical_categorizer_log_backup/" ] || mkdir -p /data/historical_categorizer_log_backup/
hist_pid=`/etc/init.d/categorizer-historical status | grep -i pid |tr -d [:alpha:] | tr -d [:punct:] | xargs`
logfilereader=($(ls -l /proc/$hist_pid/fd/ | grep $(uname -n).log  | awk '{print $9}'))
cp /proc/$hist_pid/fd/${logfilereader[0]} /data/historical_categorizer_log_backup/categorizer-historical_$(uname -n).log_$(date +%Y%m%d)
gzip -9 /data/historical_categorizer_log_backup/categorizer-historical_$(uname -n).log_$(date +%Y%m%d)
