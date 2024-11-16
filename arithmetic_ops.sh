#!/bin/bash
read -p "Ener value for X:  " x
read -p "Enter Value for Y: " y

let mul=$x*$y
echo "Mul is $mul"
let sum=$x+$y
echo "Sum is $sum"

echo "Subtraction is $(($x-$y))"

