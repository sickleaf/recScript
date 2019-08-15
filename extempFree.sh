#!/bin/bash
#
cd `dirname $0`
listCSV="./templist.csv"
shPath="/home/sickleaf/Script/timefree"
saveSH="saveTempFree.sh"
cm="#"
echo "--- Timefree Exec Start"

IFS=$'\n'
file=(`cat $listCSV`)

for line in "${file[@]}";
do
  if [ ${line:0:1} != ${cm} ]; then
	IFS=' '
	set -- $line
  	${shPath}/${saveSH} $1 $2 $3 $4
  	echo "./saveTempFree.sh $1 $2 $3 $4"
  fi
done

echo "--- Timefree Exec End"
