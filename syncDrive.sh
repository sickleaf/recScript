#!/bin/bash

# if you don't use rclone, rewrite function

# syncOption='-v --config /var/lib/jenkins/config/rclone.conf'

syncDriveFull ()
{
	sudo rclone sync $1 $2 -v --config /var/lib/jenkins/config/rclone.conf
}
syncDriveOptalk ()
{
	sudo rclone sync $1 $2 -v --config /var/lib/jenkins/config/rclone.conf
}

syncDriveBase ()
{
	sudo rclone sync $1 $2 -v --config /var/lib/jenkins/config/rclone.conf
}
syncDriveCM ()
{
	sudo rclone sync $1 $2 -v --config /var/lib/jenkins/config/rclone.conf
}
syncDriveCorner ()
{
	sudo rclone sync $1 $2 -v --config /var/lib/jenkins/config/rclone.conf
}

