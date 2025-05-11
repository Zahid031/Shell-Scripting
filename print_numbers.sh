#!/bin/bash

for (( i=1; i<50; i++))
do
    if (( i % 2 == 0 )); then
        echo "print $i"
    fi
done

