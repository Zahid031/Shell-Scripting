#!/bin/bash
######################
# Author: Zahid
# Date: 11/11/2024
#
# This script outputs the node health
#
#
# Version: v1
#
# #############
set -x
set -e

echo "Print Disk Space"
df -h
echo "Memory Usage"
free -h

echo "Cpu number"
nproc

