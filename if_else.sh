#!/bin/bash

read -p "Enter obtained marks: " marks
read -p "Bangla marks" bangla

if [ $marks -ge 80 ] && [ $bangla == "Bangla" ]
then
	echo "A+"
elif [$marks -ge 70 ]
then
	echo "A"
elif [$marks -ge 60 ]
then
	echo "A-"
else
	echo "Fail"
fi


