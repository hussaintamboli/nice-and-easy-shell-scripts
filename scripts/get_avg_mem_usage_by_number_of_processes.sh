#!/bin/bash
# Get avg memory usage by workers
# Need to improve this script

# get avg memory usage by celery workers
totalMem=0;
for i in 28571 28572 28573 28574 ; do
mem=`ps -eo pid,rss | grep $i | awk '{print $2}'`;
totalMem=`expr $totalMem + $mem`;
done;
date && echo `expr $totalMem / 4000` MB >> ~/tmp/mem-usage.txt ;

