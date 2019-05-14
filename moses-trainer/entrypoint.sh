#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

#USER_ID=${LOCAL_USER_ID:-9001}
#
#chmod a+rwx /data
#
#echo "Starting with UID : $USER_ID"
#useradd --shell /bin/bash -u $USER_ID -o -c "" -m moses
#export HOME=/home/moses
#
#exec /usr/sbin/gosu user "$@"

# wrapper port 8081
/home/moses/server-wrapper.py &

# default port 8080
/home/moses/mosesdecoder/bin/moses -f /data/model/mert-work/moses.ini --server

