#!/bin/sh

# script to install simple 'nosebleed' init script
# 'sudo ./install'

INIT_SCRIPT_DIR=/etc/init.d
INIT_SCRIPT_NAME="nosebleed"

SRC_FOLDER="src"

LOGROTATE_CONF_DIR="/etc/logrotate.d"
LOGROTATE_CONF="logrotate/nosebleed"

# just to make sure inotifywait and logrotate are installed
apt-get install inotify-tools logrotate

# copy the nosebleed startup script to INIT_SCRIPT_DIR
echo "copying "$INIT_SCRIPT_NAME" to "$INIT_SCRIPT_DIR" dir"
cp $SRC_FOLDER/$INIT_SCRIPT_NAME $INIT_SCRIPT_DIR

# make sure it is executable
echo "making "$INIT_SCRIPT_NAME" executable"
chmod +x $INIT_SCRIPT_DIR/$INIT_SCRIPT_NAME

# enable it on startup
echo "enabling "$INIT_SCRIPT_NAME" on startup"
update-rc.d $INIT_SCRIPT_NAME defaults

# copy the log rotate config file to /etc/logrotate.d/
cp $LOGROTATE_CONF $LOGROTATE_CONF_DIR/$INIT_SCRIPT_NAME

echo "...done!"
