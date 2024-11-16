#!/bin/bash
s="My name is Zahid and I am learning devops"
length=${#s}
echo "Length of the string is $length"
echo "Upper case is ${s^^}"
echo "Lower case is ${s,,}"

#Replace a  string
rs=${s/Zahid/Nahid}
echo "New changed string is $rs"

#slicing
sliceS=${s:3:4}
echo "Slice word is $sliceS"

