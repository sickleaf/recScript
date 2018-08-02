#!/bin/bash

LANG=ja_JP.utf8
#usage : $0 channel_name duration(minuites) [outputdir] [prefix]

pid=$$
date=`date '+%Y%m%d'`
#playerurl=http://radiko.jp/player/swf/player_3.0.0.01.swf
playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf

tmpdir="/home/sickleaf/Radio"

playerfile="$tmpdir/player.swf"
keyfile="$tmpdir/authkey.png"
cookiefile="$tmpdir/pre_cookie_${pid}_${date}.txt"
loginfile="$tmpdir/pre_login.txt"
checkfile="$tmpdir/pre_check.txt"
logoutfile="$tmpdir/pre_logout.txt"

mntdirectory="/mnt/transcend"
basedir="$mntdirectory/radio_base"
cmdir="$mntdirectory/radio_cm"
gdrivebasedir="$mntdirectory/gdrive/radio_base"
gdrivecmdir="$mntdirectory/gdrive/radio_cm"


spltmin=0.3
spltth=-60

syncflag=1

outdir="."


#
# Logout Function
#
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


if [ $# -le 1 ]; then
  echo "usage : $0 channel_name duration(minuites) [outputdir] [prefix] [mail] [pass]"
  exit 1
fi

if [ $# -ge 2 ]; then
  channel=$1
  DURATION=`expr $2 \* 60`
fi
if [ $# -ge 3 ]; then
  outdir=$3
fi
PREFIX=${channel}
if [ $# -ge 4 ]; then
  PREFIX=$4
  mail=$5
  pass=$6
  spltmin=$7
  spltth=$8
  syncflag=$9
fi

###
# radiko premium
###
if [ $mail ]; then
  wget -q --save-cookie=$cookiefile \
       --keep-session-cookies \
       --post-data="mail=$mail&pass=$pass" \
       -O $loginfile \
       https://radiko.jp/ap/member/login/login

  if [ ! -f $cookiefile ]; then
    echo "failed login"
    exit 1
  fi
fi

#
# check login
#
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
    -O $checkfile \
    https://radiko.jp/ap/member/webapi/member/login/check

if [ $? -ne 0 ]; then
  echo "failed login"
  exit 1
fi


#
# get player
#
if [ ! -f $playerfile ]; then
  wget -q -O $playerfile $playerurl

  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

#
# get keydata (need swftool)
#
if [ ! -f $keyfile ]; then
  swfextract -b 12 $playerfile -o $keyfile

  if [ ! -f $keyfile ]; then
    echo "failed get keydata"
    Logout
    exit 1
  fi
fi

if [ -f auth1_fms_${pid} ]; then
  rm -f auth1_fms_${pid}
fi

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
     -O auth1_fms_${pid} \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  Logout
  exit 1
fi

#
# get partial key
#
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' auth1_fms_${pid}`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' auth1_fms_${pid}`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' auth1_fms_${pid}`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f auth1_fms_${pid}

if [ -f auth2_fms_${pid} ]; then
  rm -f auth2_fms_${pid}
fi

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
     -O auth2_fms_${pid} \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f auth2_fms_${pid} ]; then
  echo "failed auth2 process"
  Logout
  exit 1
fi

echo "authentication success"

areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' auth2_fms_${pid}`
echo "areaid: $areaid"

rm -f auth2_fms_${pid}

#
# get stream-url
#

if [ -f ${channel}.xml ]; then
  rm -f ${channel}.xml
fi

wget -q "http://radiko.jp/v2/station/stream/${channel}.xml"

stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell ${channel}.xml | tail -2 | head -1`
url_parts=(`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!$1://$2 $3 $4!'`)

rm -f ${channel}.xml

#
# rtmpdump
#
#rtmpdump -q \
/usr/bin/rtmpdump \
         -r ${url_parts[0]} \
         --app ${url_parts[1]} \
         --playpath ${url_parts[2]} \
         -W $playerurl \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --quiet \
         --stop ${DURATION} \
         --flv "$tmpdir/${date}_${PREFIX}"

Logout

sudo /usr/src/FFmpeg/ffmpeg -loglevel warning -y -i "$tmpdir/${date}_${PREFIX}" -acodec libmp3lame -ab 64k "${outdir}/${date}_${PREFIX}.mp3"
if [ $? = 0 ]; then
  rm -f "$tmpdir/${date}_${PREFIX}"
fi

sudo /usr/bin/mp3splt -s -p min=$spltmin,th=$spltth -d "${basedir}/${date}_${PREFIX}" "${outdir}/${date}_${PREFIX}.mp3"

~/Script/threshold.sh "${basedir}/${date}_${PREFIX}"  "${cmdir}/${date}_${PREFIX}"

if [ $syncflag -eq 0 ]; then
	sudo cp "${outdir}/${date}_${PREFIX}.mp3" ${gdrivebasedir}
fi
if [ $syncflag -ne 0 ]; then
	sudo cp -R  ${basedir}/${date}_${PREFIX} ${gdrivebasedir}
	sudo cp -R  ${cmdir}/${date}_${PREFIX} ${gdrivecmdir}
fi

# cd ${mntdirectory}/gdrive  && sudo grive
