#/bin/bash

echo "Provide an option"
echo "a for print date"
echo "b for list of files"
echo "c to check the current location"
read choices

case $choices in 
	a)
		echo "today date is"
	        date
		;;
	b)ls;;
	c)pwd;;
	*) echo "Invalid input"
esac

