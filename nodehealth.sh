#!/bin/bash
#Author : Md. Zahid Hasan
#
#The script outputs the node health
#Version: v1

set -x
set -e #exit the script if there is error
set -o pipefail #if pipe are present then without it set -e will not work


echo "Disk Space"
df -h
echo "Memory Space"
free -g

echo "CPU"
nproc

