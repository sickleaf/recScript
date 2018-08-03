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
cpOptalk() {
	Opfile=`cat $1/${fileList} |  head -1 | awk '{print $NF}'`
	sudo cp -v ${Opfile} $2
}
