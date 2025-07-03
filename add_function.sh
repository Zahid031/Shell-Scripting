#!/bin/bash
#
greet() {
 echo " Welcome function"
}

greet

add_numbers(){
	read -p "Enter First Number: " a
	read -p "Enter Second Number: " b
	result=$(( a + b ))
	echo $result
}

add_numbers

add() {
	local sum=$(( $1 + $2 ))
	echo $sum
}

add $1 $2

