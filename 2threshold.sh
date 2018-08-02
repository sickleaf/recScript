#!/bin/bash

#$1	basedir path
#$2	cmdir path


threshold=900000

for file in *.mp3
do
	num=`wc -c < "$file"`
	if [ "$num" -lt $threshold ]
	then
		sudo mv "$1/"$file "$2"
	fi	
done
