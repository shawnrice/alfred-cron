#!/bin/bash

# This is the intermediary script.

query="$1"
if [ "$query" = "start" ]; then
	nohup sh alfred-cron.sh start > /dev/null 2>&1 &
	echo "The daemon is now running."
elif [ "$query" = "stop" ]; then
	./alfred-cron.sh stop > /dev/null 2>&1
	echo "The daemon has stopped."
elif [ "$query" = "add" ]; then
	sh manage.sh
else
	echo "Invalid command"
fi