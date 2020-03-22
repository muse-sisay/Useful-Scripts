#!/bin/bash

# a script that checks if connection is down for 5 minutes
# then waits till connection comes back again
# exits tmate session 
# creates a new tmate session and send session id using a telegram bot

TIME=$(date +"%c")
DOWN_TIME=0
LAST_SEEN=$(date +"%s")
MAX_DOWN_TIME=1200 # 20 minutes

SLEEP_INTERVAL=30 # 30 seconds

SITE=google.com   # SITE to check against

#telegram
TOKEN=
CHAT_ID=
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

BOOT_MESSAGE="gmou-pc is Powered on and Online."
POWERED_ON=1


while [ true ];do # infintely run the script
	if ! nc -zw1 google.com 443 ; then # checking if connection is down
		DOWN_TIME=$(( $(date +"%s") - $LAST_SEEN ))
	else

		if POWERED_ON -eq 1 ; then 
			curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$BOOT_MESSAGE"
			POWERED_ON=0
		fi

		DOWN_TIME=0
		LAST_SEEN=$(date +"%s")
	fi

	sleep $SLEEP_INTERVAL # lay low 

	if [ $DOWN_TIME -ge $MAX_DOWN_TIME ]; then
		
		while[ ! nc -zw1 google.com 443 ]; do 
			# loop until connection comes up
			sleep $SLEEP_INTERVAL # sleep for two minutes
		done

		#stop previous session of tmate
		tmate -S /tmp/tmate.sock kill-session
		
		#start a new tmate session
		tmate -S /tmp/tmate.sock new-session -d
		tmate -S /tmo/tmate.sock wait tmate-ready
		
		#extract the session id
		SESSION_ID=$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
		LOCAL_IPV4=$(ifdata -pa eth0)

		# compose the message
		MESSAGE="\[ $TIME \]
		- Session $SESSION_ID 
		- IPV4 $LOCAL_IPV4"

		#email the session id - changed to telegram
		curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE"

		sleep (($SLEEP_INTERVAL * 10 )) # sleeps for 30 * 10 seconds = 6 min
		
		# reset everything
		DOWN_TIME=0
		LAST_SEEN=$(date +"%s")

	fi

done
