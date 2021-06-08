#!/bin/bash
randomNumber=$RANDOM
echo $randomNumber
while [ "$randomNumber" -ge 100 ];
		do
  			randomNumber=$RANDOM
		done
echo $randomNumber