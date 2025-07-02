#!/bin/bash
#
counter=1

while (( counter < 5 ))
do
	echo "Count: $counter"
	(( counter++ ))
done


c=1
while [ $c -le 5 ]
do
	echo " $c "
	(( c++ ))
done
