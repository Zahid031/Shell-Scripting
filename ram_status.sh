#!/bin/bash

FS=$(free -mt | grep "Totall" | awk '{print $4}')
#FS=4000
if [[ $FS -lt 8000 ]]
then
	echo "Ram is running low"
else
	echo "Ram is sufficient"
fi

