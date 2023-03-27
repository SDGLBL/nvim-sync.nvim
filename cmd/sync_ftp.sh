#!/bin/sh
if [ "upload" = "$1" ]; then
	ncftpput -t 1 -m -u login_name -p login_password -P 21 remote_host remote_path/"$2" "$(dirname "$0")"/"$2"/"$3"
elif [ 'download' = "$1" ]; then
	ncftpget -t 1 -u login_name -p login_password -P 21 remote_host "$(dirname "$0")"/"$2" remote_path/"$2"/"$3"
fi
