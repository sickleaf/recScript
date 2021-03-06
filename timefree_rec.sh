#!/bin/bash
# original: https://gist.github.com/saiten/875864/
# 20161017 modified by mapi
cd `dirname $0`
ver="2016.10.17"
#genre=Radio


tmpdir=/tmp
savedir=/mnt/transcend/radio

if [ $# -eq 4 ]; then
  channel=$1
  title=$2
  output=$tmpdir/$2
  fromtime=$3
  totime=$4
elif [ $# -eq 6 ]; then
  channel=$1
  title=$2
  output=$tmpdir/$2
  fromtime=$3
  totime=$4
  mail=$5
  pass=$6
else
  echo "usage : $0 channel_name outputfile fromtime totime [mail] [pass]"
  exit 1
fi

recdate=`echo $fromtime | cut -c 1-8`

echo "--- Record Information (Ver. $ver)"
echo ""
echo "File      : $output"
echo "Channel   : $channel"
echo "FromTime  : $fromtime"
echo "ToTime    : $totime"
echo ""
echo "Mail      : $mail"
echo "Pass      : $pass"
echo ""
echo "Recdate	: $recdate"
echo ""

auth1_fms="${channel}.auth1_fms"
auth2_fms="${channel}.auth2_fms"
#------------------------------------------------------------
playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf
cookiefile=/tmp/cookie.txt
playerfile=/tmp/player.swf
keyfile=/tmp/authkey.png

###
# radiko premium
###
if [ $mail ]; then
  wget -q --save-cookie=$cookiefile \
       --keep-session-cookies \
       --post-data="mail=$mail&pass=$pass" \
       https://radiko.jp/ap/member/login/login

  if [ ! -f $cookiefile ]; then
    echo "failed login"
    exit 1
  fi
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
    exit 1
  fi
fi

if [ -f $auth1_fms ]; then
  rm -f $auth1_fms
fi

#
# access auth1_fms
#
wget  \
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
  echo "failed auth1 process"
  exit 1
fi

#
# get partial key
#
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' ${auth1_fms}`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' ${auth1_fms}`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' ${auth1_fms}`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f $auth1_fms

if [ -f $auth2_fms ]; then
  rm -f $auth2_fms
fi

#
# access auth2_fms
#
wget  \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_ts" \
     --header="X-Radiko-App-Version: 4.0.0" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-AuthToken: ${authtoken}" \
     --header="X-Radiko-PartialKey: ${partialkey}" \
     --post-data='\r\n' \
     --load-cookies $cookiefile \
     --no-check-certificate \
     -O ${auth2_fms} \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f $auth2_fms ]; then
  echo "failed auth2 process"
  exit 1
fi

echo "authentication success"

areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' ${auth2_fms}`
echo "areaid: $areaid"

rm -f $auth2_fms

#
# get stream-url
#

wget  \
	--header="pragma: no-cache" \
	--header="Content-Type: application/x-www-form-urlencoded" \
	--header="X-Radiko-AuthToken: ${authtoken}" \
	--header="Referer: ${playerurl}"\
	--post-data='flash=1' \
     	--load-cookies $cookiefile \
	--no-check-certificate \
	-O $output.m3u8 \
	"https://radiko.jp/v2/api/ts/playlist.m3u8?l=15&station_id=$channel&ft=$fromtime&to=$totime"

stream_url=`grep radiko $output.m3u8`

echo "--- wget end\n"

#ffmpeg -loglevel warning -y -i "$stream_url" -acodec libmp3lame -ab 64k "${savedir}/${title}_${recdate}.mp3"
ffmpeg -loglevel warning -y -i "$stream_url" -acodec copy "$output.aac"

echo "--- ffmpeg end\n"

MP4Box -noprog -sbr -add "$output.aac" -new "$output.m4a"

echo "--- MP4Box end\n"

rm "$output.m3u8" "$output.aac"


echo "--- Record end\n"

