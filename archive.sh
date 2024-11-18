#!/bin/bash
#November 18 2024 
#Variable
BASE=
DAYS=10
DEPTH=1
RUN=0

#check if the directory is present or not

if [ ! -d $BASE ]
then
	echo "directory does  n ot exist :$BASE"
	exit 1
fi

#create archive folder
if [! -d $BASE/archive ]
then
	mkdir $BASE/archive
fi

#find the list of files larger than 20 mb
#
#
for i in 'find $BASE -maxdepth $DEPTH -type f -size +20MB'
do
	if [ $RUN -eq 0 ]
	then
		gzip $i || exit 1
		mv $i.gz $BASE/archive || exit 1
	fi

done


