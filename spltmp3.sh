#!/bin/bash

#######
# arg1:	srcmp3path
# arg2:	dstpath
# arg3:	prefix
# pattern1 full ) spltmp3.sh /mnt/transcend/music/test.mp3 /mnt/transcend/cutmp3/
# pattern2 op only) spltmp3.sh /mnt/transcend/music/test.mp3 /mnt/transcend/cutmp3/
# pattern3 cut default[0.3,-60]) spltmp3.sh /mnt/transcend/music/test.mp3 /mnt/transcend/cutmp3/
# pattern4 cut default[0.3,-60]) spltmp3.sh /mnt/transcend/music/test.mp3 /mnt/transcend/cutmp3/
#######

srcmp3path=$1
dstpath=$2
prefix=$3

echo "################"  
echo "splt:: Script Start -- $(date +%Y%m%d_%H%M%S)" 

for directory in `find $srcpath `; do
	if $prefix; then
		echo $directory
		sudo mv $directory $dstpath
sudo /usr/bin/mp3splt -s -p min=0.3,th=-60 -d "${outdir}/${PREFIX}_${date}" "${outdir}/${PREFIX}_${date}.mp3"
	fi	
done

echo "splt:: Script End -- $(date +%Y%m%d_%H%M%S)" 
echo "################" 
