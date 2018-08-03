#!/bin/bash

################################################

pid=$$
date=`date '+%Y%m%d'`

scriptDir=$(cd $(dirname $0); pwd);
configFileName=config.sh
functionFileName=function.sh

# read *Name parameter and function
. ./${configFileName}
. ./${functionFileName}

playerURL=`configGrep playerURL`

userName=`configGrep userName`

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
#checkfile=${tmpPath}/pre_check.txt
loginfile=${tmpPath}/pre_login.txt
logoutfile=${tmpPath}/pre_logout.txt
stationXML=${tmpPath}/${stationID}${pid}.xml
savefile=${tmpPath}/${date}_${PREFIX}

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
syncCMName=`configGrep syncCMName`
syncCornerName=`configGrep syncCornerName`

syncFullPath=${syncPath}/${syncFullName}
syncOptalkPath=${syncPath}/${syncOptalkName}
syncCMPath=${syncPath}/${syncCMName}
syncCornerPath=${syncPath}/${syncCornerName}

################################################

spltmin=0.3
spltth=-60

syncflag=1
outdir="."

################################################

if [ $# -le 1 ]; then
  echo "usage : $0 stationID duration(minuites) [outputdir] [prefix] [mail] [pass]"
  exit 1
fi
if [ $# -ge 4 ]; then
  stationID=$1
  DURATION=`expr $2 \* 60`
  outdir=$3
  PREFIX=$4
  spltmin=$5
  spltth=$6
  syncflag=$9
fi

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
  wget -O ${playerfile} ${playerurl}
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

#
# rtmpdump
#
#rtmpdump -q $
/usr/bin/rtmpdump \
         -r ${url_parts[0]} \
         --app ${url_parts[1]} \
         --playpath ${url_parts[2]} \
         -W $playerURL \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --quiet \
         --stop ${DURATION} |\
         mpv - --quiet
#         --flv "$tmpPath/${date}_${PREFIX}"
Logout

#sudo /usr/src/FFmpeg/ffmpeg -loglevel warning -y -i "$tmpPath/${date}_${PREFIX}" -acodec libmp3lame -ab 64k "${outdir}/${date}_${PREFIX}.mp3"
#if [ $? = 0 ]; then
#  rm -f "$tmpPath/${date}_${PREFIX}"
#fi
#
#sudo /usr/bin/mp3splt -s -p min=$spltmin,th=$spltth -d "${basedir}/${date}_${PREFIX}" "${outdir}/${date}_${PREFIX}.mp3"
#
#if [ $syncflag -eq 0 ]; then
#	echo "[start]copy file without split"
#	sudo cp "${outdir}/${date}_${PREFIX}.mp3" ${gdrivebasedir}
#	echo "[end]copy file without split"
#fi
#
#if [ $syncflag -ne 0 ]; then
#	echo "[start]copy base/cm folder after split"
#	sudo cp -R  ${basedir}/${date}_${PREFIX} ${gdrivebasedir}
#	sudo cp -R  ${cmdir}/${date}_${PREFIX} ${gdrivecmdir}
#	echo "[end]copy base/cm folder after split"
#fi

