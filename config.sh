#!/bin/bash

playerURL=http://radiko.jp/apps/js/flash/myplayer-release.swf
loginURL=https://radiko.jp/ap/member/login/login

userName=radipi

# mail is intentionally left blank
# scriptDir is in recRadiko.sh
mail=wakuraba.0@gmail.com
keyDirName=passkey
secretKey=${scriptDir}/${keyDir}/seckey
cipherText=${scriptDir}/${keyDir}/cipher
pass=$(openssl rsautl -decrypt -inkey ${secretKey} -in ${cipherText})

# [1] temporary save in local storage (tmp)
#
# tmpPath=/home/${userName}/${tmpName}
# tmpResourcePath=${tmpPath}/${tmpResourceName}
# tmpFullPath=${tmpResoucePath}/${tmpFullName}
# tmpCutPath=${tmpResoucePath}/${tmpCutName}
# ex)
#	/home/radipi/radio					<- tmpPath
#				 player.swf
#				 authkey.png
#				 /resource				<- tmpResourcePath
#					/Full				<- tmpFullPath
#					/Cut				<- tmpCutPath
#						/YYYYMMDD_programID

tmpName=radio
tmpResourceName=resource
tmpFullName=Full
tmpCutName=Cut

# [2] permanently save in external drive (mnt)
# mntPath=/mnt/${mntName}
# mntResourcePath=${mntPath}/${mntResourceName}
# mntFullPath=${mntResoucePath}/${mntFullName}
# mntCutPath=${mntResoucePath}/${mntCutName}
# ex)
#	/mnt/transcend					<- mntPath
#				/radio				<- mntResourcePath
#					/Full			<- mntFullPath (backup folder)
#						YYYYMMDD_programID.mp3
#					/Cut			<- mntCutPath
#						/YYYYMMDD_programID

mntName=transcend
mntResourceName=radio
mntFullName=Full
mntCutName=Cut

# [3] sync folder (sync)
# syncPath=${syncPath}
# SyncXXXPath=${syncPath}/${SyncXXXName}
# ex)
#	/mnt/transcend/sync				<- syncPath 
#					/Full			<- syncFullPath 
#						YYYYMMDD_programID.mp3
#					/optalk			<- syncOptalkPath
#					/cm				<- syncCMPath
#					/corner			<- syncCornerPath
#

syncPath=/mnt/transcend/sync
syncFullName=full
syncOptalkName=optalk
syncCMName=cm
syncCornerName=corner
