#!/bin/bash

function copyBase(){
	srcDir=$1
	origDstDir=$2
	threshold=$3

	origDirId=${origDstDir##*/}
	origDirPath=${origDstDir%/*}
	
	dirId=`echo ${origDirId} | awk -F"_" '{print $2"_"$1"_"$3}'`
	dstDir=${origDirPath}/${dirId}
	mkdir -p ${dstDir}

	find ${srcDir} -type f | 
	while read f; do
		filesize=`wc -c < ${f}`
		if [ ${filesize} -gt ${threshold} ]; then
			cp -v ${f} ${dstDir}
		fi
	done
}

function copyOptalk(){
	srcDir=$1
	dstDir=$2
	threshold=$3

	find ${srcDir} -type f | 
	while read f; do
		filesize=`wc -c < ${f}`
		if [ ${filesize} -gt ${threshold} ]; then
			cp -v ${f} ${dstDir}
			exit
		fi
	done
}

function copyCorner(){
	srcDir=$1
	dstDir=$2
	sizeOrder=`echo $3 | cut -d"," -f1`
	preCutCommand=`echo $3 | cut -d"," -f2`
	preCutArg=`echo $3 | cut -d"," -f3`
	threshold=`echo $3 | cut -d"," -f4`
	sedOption=`echo $3 | cut -d"," -f5`
	grepOption=`echo $3 | cut -d"," -f6`

	mkdir -p ${dstDir}

	anchorFile=`getAnchorFile ${srcDir} ${sizeOrder} ${preCutCommand} ${preCutArg} ${threshold} ${sedOption}`
	
	echo ${anchorFile}
	
	find ${srcDir} -type f -printf "%s %h/%f\n" |
	awk -v "thd=${threshold}"  '$1>thd{print}' |
	grep ${grepOption} ${anchorFile} |
	cut -d" " -f2 |
	xargs -I@ cp -v @ ${dstDir}

}

# get n-th largest file
## sizeOrder : sort -k1,1rn
## timeOrder: sort -k2,2
function getAnchorFile(){

	dir=$1
	sizeOrder=$2
	preCutCommand=$3
	preCutArg=$4
	threshold=$5
	sedOption=$6

	if ${sizeOrder} ;then
		sortOption=" -k1,1rn"
	else
		sortOption=" -k2,2"
	fi

	find ${dir} -name *.mp3 -printf '%s %f\n' |
	${preCutCommand} ${preCutArg} |
	sort ${sortOption} |
	awk -v thd=${threshold} '$1>thd{print}' |
	sed -n ${sedOption} |
	cut -d" " -f2
}
