#!/bin/bash

count=0
num=10

while [[ $count -le $num ]]
do
	echo "Value of Counter variable is $count"
	let count++
done

while true
do
	echo "Hiiii its running infinity loop"
	sleep 2s
done


