#!/bin/bash

################################################

pid=$$
date=`date '+%Y%m%d'`

scriptDir=$(cd $(dirname $0); pwd);
cd ${scriptDir}
configFileName=config.sh
functionFileName=function.sh
syncFileName=syncDrive.sh

# read *Name parameter and function
. ./${configFileName}
. ./${functionFileName}
. ./${syncFileName}

playerURL=`configGrep playerURL`
loginURL=`configGrep loginURL`

userName=`configGrep userName`

fileList=`configGrep fileList`

################################################
# [1] tmp
################################################

tmpName=`configGrep tmpName`
tmpResourceName=`configGrep tmpResourceName`
tmpFullName=`configGrep tmpFullName`
tmpCutName=`configGrep tmpCutName`

tmpPath=/home/${userName}/${tmpName}
tmpResourcePath=${tmpPath}/${tmpResourceName}
tmpFullPath=${tmpResourcePath}/${tmpFullName}
tmpCutPath=${tmpResourcePath}/${tmpCutName}

playerfile=${tmpPath}/player.swf
keyfile=${tmpPath}/authkey.png
auth1_fms=${tmpPath}/auth1_fms
auth2_fms=${tmpPath}/auth2_fms
cookiefile=${tmpPath}/pre_cookie_${pid}_${date}.txt
loginfile=${tmpPath}/pre_login.txt
logoutfile=${tmpPath}/pre_logout.txt

################################################
# [2] mnt
################################################

mntName=`configGrep mntName`
mntResourceName=`configGrep mntResourceName`
mntFullName=`configGrep mntFullName`
mntCutName=`configGrep mntCutName`

mntPath=/mnt/${mntName}
mntResourcePath=${mntPath}/${mntResourceName}
mntFullPath=${mntResourcePath}/${mntFullName}
mntCutPath=${mntResourcePath}/${mntCutName}

################################################
# [3] sync
################################################

syncPath=`configGrep syncPath`

syncFullName=`configGrep syncFullName`
syncOptalkName=`configGrep syncOptalkName`
syncBaseName=`configGrep syncBaseName`
syncCMName=`configGrep syncCMName`
syncCornerName=`configGrep syncCornerName`

syncRemoteName=`configGrep syncRemoteName`

syncFullPath=${syncPath}/${syncFullName}
syncOptalkPath=${syncPath}/${syncOptalkName}
syncBasePath=${syncPath}/${syncBaseName}
syncCMPath=${syncPath}/${syncCMName}
syncCornerPath=${syncPath}/${syncCornerName}

syncRemoteFullPath=${syncRemoteName}/${syncFullName}
syncRemoteOptalkPath=${syncRemoteName}/${syncOptalkName}
syncRemoteBasePath=${syncRemoteName}/${syncBaseName}
syncRemoteCMPath=${syncRemoteName}/${syncCMName}
syncRemoteCornerPath=${syncRemoteName}/${syncCornerName}


################################################

spltmin=0.3
spltth=-60
threshold=900000

syncflag=1
outdir="."

################################################

if [ $# -le 1 ]; then
	echo "usage : $0 stationID duration[minuites] prefix syncflag spltmin spltth (threshold cornerName)"
  exit 1
fi
if [ $# -ge 4 ]; then
  stationID=$1
  DURATION=`expr $2 \* 60`
  PREFIX=$3
  syncflag=$4
fi

if [ $# -ge 6 ]; then
  spltmin=$5
  spltth=$6
fi

if [ $# -ge 7 ]; then
  threshold=$7
  cornerName=$8
fi


################################################

fileBaseName=${date}_${PREFIX}
stationXML=${tmpPath}/${stationID}${pid}.xml
savefile=${tmpPath}/${fileBaseName}

tmpFullMP3Path=${tmpFullPath}/${fileBaseName}.mp3
mntFullMP3Path=${mntFullPath}/${fileBaseName}.mp3
tmpCutDirPath=${tmpCutPath}/${fileBaseName}
mntCutDirPath=${mntCutPath}/${fileBaseName}

################################################

###
# radiko premium
###
if [ $mail ]; then
  wget -q --save-cookie=$cookiefile \
       --keep-session-cookies \
       --post-data="mail=${mail}&pass=${pass}" \
       -O ${loginfile} \
       ${loginURL}

  if [ ! -f $cookiefile ]; then
    echo "failed login"
    exit 1
  fi
fi

#
# check login
#
#wget -q $
#    --header="pragma: no-cache" $
#    --header="Cache-Control: no-cache" $
#    --header="Expires: Thu, 01 Jan 1970 00:00:00 GMT" $
#    --header="Accept-Language: ja-jp" $
#    --header="Accept-Encoding: gzip, deflate" $
#    --header="Accept: application/json, text/javascript, */*; q=0.01" $
#    --header="X-Requested-With: XMLHttpRequest" $
#    --no-check-certificate $
#    --load-cookies $cookiefile $
#    --save-headers $
#    -O $checkfile $
#    https://radiko.jp/ap/member/webapi/member/login/check
#
#if [ $? -ne 0 ]; then
#  echo "failed login"
#  exit 1
#fi


    #
    # delete previous setting file
    #
    rm -f ${keyfile} 
    rm -f ${auth1_fms}
    rm -f ${auth2_fms}
#
# get player
#
if [ ! -f $playerfile ]; then
  wget -O ${playerfile} ${playerURL}
  if [ ! -f ${playerfile} ]; then
    echo "[stop] failed get player (${playerfile})" 1>&2 ; exit 1
  fi
fi

#
# get keydata (need swftool)
#
if [ ! -f ${keyfile} ]; then
  swfextract -b 12 ${playerfile} -o ${keyfile}
  if [ ! -f ${keyfile} ]; then
    Logout
    echo "[stop] failed get keydata (${keyfile})" 1>&2 ; exit 1
  fi
fi

#if [ -f \${auth1_fms} ]; then
#  rm -f \${auth1_fms}
#fi

#
# access auth1_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_ts" \
     --header="X-Radiko-App-Version: 4.0.0" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --post-data='\r\n' \
     --no-check-certificate \
     --load-cookies $cookiefile \
     --save-headers \
     -O ${auth1_fms} \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  Logout
  echo "[stop] failed auth1 process (${auth1_fms})" 1>&2 ; exit 1
fi

#
# get partial key
#
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' ${auth1_fms}`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' ${auth1_fms}`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' ${auth1_fms}`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f ${auth1_fms}

#if [ -f auth2_fms_${pid} ]; then
#  rm -f auth2_fms_${pid}
#fi

#
# access auth2_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_ts" \
     --header="X-Radiko-App-Version: 4.0.0" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-Authtoken: ${authtoken}" \
     --header="X-Radiko-Partialkey: ${partialkey}" \
     --post-data='\r\n' \
     --load-cookies $cookiefile \
     --no-check-certificate \
     -O ${auth2_fms} \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f ${auth2_fms} ]; then
  Logout
  echo "[stop] failed auth2 process (${auth2_fms})" 1>&2 ; exit 1
fi

echo "authentication success"

areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' ${auth2_fms}`
echo "areaid: $areaid"

rm -f ${auth2_fms}

#
# get stream-url
#

wget -q \
	--load-cookies $cookiefile \
	--no-check-certificate \
	-O ${stationXML} \
    "https://radiko.jp/v2/station/stream/${stationID}.xml"

  if [ $? -ne 0 -o ! -f ${stationXML} ]; then
      echo "[stop] failed stream-url process (stationID=${stationID})"
      rm -f ${stationXML} ; show_usage ; exit 1
  fi

  stream_url=`echo "cat /url/item[1]/text()" | \
          xmllint --shell ${stationXML} | tail -2 | head -1`
  url_parts=(`echo ${stream_url} | \
          perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!$1://$2 $3 $4!'`)
  rm -f ${stationXML}

	echo "[url_parts0] ${url_parts[0]}"
	echo "[url_parts1] ${url_parts[1]}"
	echo "[url_parts2] ${url_parts[2]}"



################################################
# [1] local
################################################

# record files
/usr/bin/rtmpdump \
         -r ${url_parts[0]} \
         --app ${url_parts[1]} \
         --playpath ${url_parts[2]} \
         -W $playerURL \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --quiet \
         --stop ${DURATION} \
         --flv ${savefile}
Logout

# convert localfile to mp3
ffmpeg -loglevel warning -y -i "${savefile}" -acodec libmp3lame -ab 64k "${tmpFullMP3Path}"

# delete localfile
if [ $? = 0 ]; then
	rm -f ${savefile};
fi


# detect silence / cut mp3file using mp3splt
mp3splt -q -N -s -p min=${spltmin},th=${spltth} -d "${tmpCutDirPath}" "${tmpFullMP3Path}"

# export file list in tmpCutDirPath
if [ -d ${tmpCutDirPath}  ]; then
	cutNum=`ls -l ${tmpCutDirPath}/*.mp3  | wc -l`
	ls -ld ${tmpCutDirPath}/*.mp3 | awk '{print $5,$NF}' > ${tmpCutDirPath}/${fileList}
fi


################################################
# [2] mnt
################################################

## copy full mp3
if [ -s ${tmpFullMP3Path}  ]; then
	sudo cp -v ${tmpFullMP3Path} ${mntFullMP3Path}
	ls -ld ${mntFullMP3Path} | awk '{print $5,$NF}' 
fi

## copy cut files with dir
if [ -d ${tmpCutDirPath}  ]; then
	sudo cp -Rv ${tmpCutDirPath} ${mntCutDirPath}
fi


################################################
# [3] sync
################################################

## execute copy job according to syncflag

echo ""

if [ `echo ${syncflag} | grep "full" ` ]; then
	echo "[full]START"
	echo "#tmpFullMP3Path:${tmpFullMP3Path}"
	echo "#syncFullPath:${syncFullPath}"
	cpFull ${tmpFullMP3Path} ${syncFullPath}
	echo "[full]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "optalk" ` ]; then
	echo "[optalk]START"
	echo "#tmpCutDirPath:${tmpCutDirPath}"
	echo "#syncOptalkPath:${syncOptalkPath}"
	echo "#threshold:${threshold}"
	cpOptalk ${tmpCutDirPath} ${syncOptalkPath} ${threshold}
	echo "[optalk]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "base" ` ]; then
	echo "[base]START"
	echo "#tmpCutDirPath:${tmpCutDirPath}"
	echo "#syncBasePath:${syncBasePath}"
	echo "#threshold:${threshold}"
	cpBase ${tmpCutDirPath} ${syncBasePath} ${threshold}
	echo "[base]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "cm" ` ]; then
	echo "[cm]START"
	echo "#tmpCutDirPath:${tmpCutDirPath}"
	echo "#syncCMPath:${syncCMPath}"
	echo "#threshold:${threshold}"
	cpCM ${tmpCutDirPath} ${syncCMPath} ${threshold}
	echo "[cm]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "corner" ` ]; then
	cpCorner ${tmpCutDirPath} ${syncCornerPath} ${cornerName}
fi

## sync drive

if [ `echo ${syncflag} | grep "full" ` ]; then
	echo "[sync(full)]START"
	syncDriveFull ${syncFullPath} ${syncRemoteFullPath}
	echo "[sync(full)]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "optalk" ` ]; then
	echo "[sync(optalk)]START"
	syncDriveOptalk ${syncOptalkPath} ${syncRemoteOptalkPath}
	echo "[sync(optalk)]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "base" ` ]; then
	echo "[sync(base)]START"
	syncDriveBase ${syncBasePath} ${syncRemoteBasePath}
	echo "[sync(base)]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "cm" ` ]; then
	echo "[sync(cm)]START"
	syncDriveCM ${syncCMPath} ${syncRemoteCMPath}
	echo "[sync(cm)]END"
	echo ""
fi

if [ `echo ${syncflag} | grep "corner" ` ]; then
	echo "[sync(corner)]START"
	syncDriveCorner ${syncCornerPath} ${syncRemoteCornerPath}
	echo "[sync(corner)]END"
	echo ""
fi

## remove local files
if [ -s ${tmpFullMP3Path} -a -s ${mntFullMP3Path} ]; then
	rm ${tmpFullMP3Path}
	rm -r ${tmpCutDirPath}
fi

