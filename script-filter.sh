if [ ! -f "alfred.bundler.sh" ]; then
	echo "Alfred Cron needs to set itself up. Wait just a moment and try again."
	sh setup.sh setup > /dev/null 2>&1 &
	exit 0
fi

. variables
. setup.sh
. "$BashWorkflowHandler"

running=`sh alfred-cron.sh check`

if [ ! -z "$1" ]; then
	arg="$1"
fi

if [ "$running" = "FALSE" ]; then
	addResult "" "" "Cron is off" "Cron status" "icons/red-x.png" "yes" "status"
	addResult "" "start" "Start Cron" "Cron" "icons/blue-clock.png" "yes" "start"
	addResult "" "add" "Add a Cron Entry" "Cron" "icons/blue-clock.png" "yes" "add"
else
	pid=`cat "$pidFile"`
	addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/green-check.png" "yes" "status"
	addResult "" "stop" "Stop Cron" "Cron" "icons/blue-clock.png" "yes" "stop"
	addResult "" "add" "Add a Cron Entry" "Cron" "icons/blue-clock.png" "yes" "add"
fi

# Print the results
getXMLResults