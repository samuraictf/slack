#!/usr/bin/env bash
set -ex
export SLACK_PATH=$(dirname $(readlink -e "$0"))

#
# Read all of the configuration variables, to set up the environment.
#
for config in "$SLACK_PATH/config/"*; do
    source "$config"
done

if [ -z "$DEPLOY_SERVER" ]; then
	log "ERROR: $0 requires a deploy server to execute."
	exit 1
fi

if [ -z "$SLACK_URL" ]; then
    log "ERROR: $0 requires a configured Slack Webhook to execute."
    exit 1
fi

#
# Filename of FIFO on gamebox
#
export FIFO="/home/$DEPLOY_USER/slack"

#
# Gracefully handle ctrl+c
#
ctrl_c() {
    echo "Trapped Ctrl-C"
    slack_msg_custom "$ERRORCHAN" "ssh-slack" "Trapped Ctrl+C, no longer monitoring \`$FIFO\` $(cat $FILE)"
    log "Trapped Ctrl+C, no longer monitoring \`$FIFO\` $(cat $FILE)"
    exit
}
trap ctrl_c INT

FILE=$(mktemp)
while true; do
	$DEPLOY_SSH -n "[ -p '$FIFO' ] || (mkfifo '$FIFO' && chmod 600 '$FIFO'); read line < '$FIFO'; echo \$line" > $FILE 2>&1
    ERR=$?
    if [[ $ERR != 0 ]] ; then
        slack_msg_custom "$ERRORCHAN" "ssh-slack" "Got error $ERR, no longer monitoring \`$FIFO\` $(cat $FILE)"
        log "Got error $ERR, no longer monitoring \`$FIFO\` $(cat $FILE)"
        break
    fi

    xxd < $FILE

    {
        read -d " " user
        read -d " " channel
        message=$(cat)
    } < $FILE

    echo user $user
    echo chan $channel
    echo msg  $message

    slack_msg_custom "$channel" "$user" "$message"
    log "#$channel: $user - $message"

    mv $FILE $FILE.last
done
