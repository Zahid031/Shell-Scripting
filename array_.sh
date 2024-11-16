#!/bin/bash
#Array

myarr=(1 20 2.5 Hello "Hii Hello")
echo "Value in second index ${myarr[2]}"
echo "All values in array are ${myarr[*]}"

#length of an array 
echo "Length of an array is ${#myarr[*]}"

echo "values from index 2 to 3 ${myarr[*]:2:2}"

#updae array

myarr+=(6 7 8)
echo "value of new array ${myarr[*]}"

#key value pair
declare -A arr
arr=([name]=Zahid [age]=25 [city]=Kushtia)
echo "My name is ${arr[name]}"


