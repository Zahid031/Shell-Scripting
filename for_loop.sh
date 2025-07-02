#!/bin/bash
#set -e
#set -x

for i in 1 2 3 4 5
do
	echo $i
done

for i in {1..5}
do
	echo $i
done

for i in 123 
do
	echo $i
done



arr2=( 1 2 3 4 5 6 )
length=${#arr2[*]}
for ((i=0; i<$length; i++))
do
	echo "${arr2[$i]}"
done
