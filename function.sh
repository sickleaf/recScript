#!/bin/bash

configGrep ()
{
  ret=$(cat ${scriptDir}/${configFileName} | grep -v "#" | grep $1 | cut -d "=" -f 2)
  echo $ret
}

tmpDebug() {
  echo "##"
  echo "#[tmpName]"${tmpName}
  echo "#[tmpResourceName]"${tmpResourceName}
  echo "#[tmpPath]"${tmpPath}
  echo "#[tmpResourcePath]"${tmpResourcePath}
  echo "#[tmpFullPath]"${tmpFullPath}
  echo "#[tmpCutPath]"${tmpCutPath}
  echo "##"
  echo "#[mntName]"${mntName}
  echo "#[mntResourceName]"${mntResourceName}
  echo "#[mntPath]"${mntPath}
  echo "#[mntResourcePath]"${mntResourcePath}
  echo "#[mntFullPath]"${mntFullPath}
  echo "#[mntCutPath]"${mntCutPath}
  echo "##"
  echo "#[syncPath]"${syncPath}
  echo "#[syncFullPath]"${syncFullPath}
  echo "#[syncOptalkPath]"${syncOptalkPath}
  echo "#[syncCMPath]"${syncCMPath}
  echo "#[syncCornerPath]"${syncCornerPath}
}

# Logout Function

Logout () {
   wget -q \
     --header="pragma: no-cache" \
     --header="Cache-Control: no-cache" \
     --header="Expires: Thu, 01 Jan 1970 00:00:00 GMT" \
     --header="Accept-Language: ja-jp" \
     --header="Accept-Encoding: gzip, deflate" \
     --header="Accept: application/json, text/javascript, */*; q=0.01" \
     --header="X-Requested-With: XMLHttpRequest" \
     --no-check-certificate \
     --load-cookies $cookiefile \
     --save-headers \
     -O $logoutfile \
     https://radiko.jp/ap/member/webapi/member/logout

    if [ -f $cookiefile ]; then
        rm -f $cookiefile
    fi
    echo "=== Logout: radiko.jp ==="
}

# $1:tmpFullMP3Path
# $2:syncFullPath
cpFull(){
	sudo cp -v $1 $2
}

# $1:tmpCutDirPath
# $2:syncOptalkPath
# $3:threthold
cpOptalk() {
	IFS=$'\n'
	for EACHFILE in `cat $1/${fileList}`;
	do
		fsize=`echo ${EACHFILE} | awk '{print $1}'`
		fpath=`echo ${EACHFILE} | awk '{print $2}'`
#		echo "fsize=$fsize,threthold=$3"
		if [ ! -z "$3" -a  ${fsize} -gt "$3" ]; then
			sudo cp -v ${fpath} $2
			exit
		fi
	done;

}

# $1:tmpCutDirPath
# $2:syncOptalkPath
# $3:threthold
cpBase() {
	IFS=$'\n'
	for EACHFILE in `cat $1/${fileList}`;
	do
		fsize=`echo ${EACHFILE} | awk '{print $1}'`
		fpath=`echo ${EACHFILE} | awk '{print $2}'`
#		echo "fsize=$fsize,threthold=$3"
		if [ ! -z "$3" -a  ${fsize} -gt "$3" ]; then
			sudo cp -v ${fpath} $2
		fi
	done;
}

# $1:tmpCutDirPath
# $2:syncOptalkPath
# $3:threthold
cpCM() {
	IFS=$'\n'
	for EACHFILE in `cat $1/${fileList}`;
	do
		fsize=`echo ${EACHFILE} | awk '{print $1}'`
		fpath=`echo ${EACHFILE} | awk '{print $2}'`
#		echo "fsize=$fsize,threthold=$3"
		if [ ! -z "$3" -a  ${fsize} -lt "$3" ]; then
			sudo cp -v ${fpath} $2
		fi
	done;

}

# $1:tmpCutDirPath
# $2:syncOptalkPath
# $3:cornerName
#cpCorner() {
#}
 
