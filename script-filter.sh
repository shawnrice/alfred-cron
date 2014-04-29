# if [ ! -f "alfred.bundler.sh" ]; then
# 	echo "Alfred Cron needs to set itself up. Wait just a moment and try again."
# 	sh setup.sh setup > /dev/null 2>&1 &
# 	exit 0
# fi

. variables
. setup.sh
. "$BashWorkflowHandler"

running=`sh alfred-cron.sh check`

if [ ! -z "$1" ]; then
	arg="$1"
fi

if [[ "$arg" =~ " " ]]; then
	second=`echo "$arg" | awk '{split($0,array," ")} END{print array[2]}'`
	arg=`echo "$arg" | awk '{split($0,array," ")} END{print array[1]}'`
fi

if [[ "$arg" =~ ^l ]] || [[ "$arg" =~ ^ed ]]; then
	dir=`find "$scriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'No cron jobs have been defined.' "$count" 'icons/warning.png' 'no' ''
	else
		for f in "$scriptDir/"*
		do
			if [ -f "$f" ]; then
				file=$(basename "$f")
				name=`echo $file | tr '_' ' '`
				name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
				if [ -e "$enabledScriptDir/$file" ]; then
					icon='icons/circle_ok.png'
				else
					icon='icons/circle.png'
				fi
				if [ ! -z "$second" ]; then
					if [[ "$name" =~ "$second" ]]; then
						addResult "edit-$file" "edit-$file" "Edit $name" "$second" "$icon" "yes" "edit-$file"
					fi
				else
					if [[ `echo $icon | grep '_ok'` ]]; then
						addResult "edit-$file" "edit-$file" "Edit $name" "Job Enabled" "$icon" "yes" "edit-$file"
					else
						addResult "edit-$file" "edit-$file" "Edit $name" "Job Disabled" "$icon" "yes" "edit-$file"
					fi
				fi
			fi
		done
	fi
elif [[ "$arg" =~ ^di ]]; then
	dir=`find "$enabledScriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	# echo $dir
	if [ -z "$dir" ]; then
		addResult '' '' 'There are no enabled cron jobs.' '' 'icons/warning.png' 'no' ''
	else
		yes='false'
		for f in "$enabledScriptDir/"*
		do
			file=$(basename "$f")
			if [ ! "$file" = "*" ]; then
				yes='true'
				name=`echo $file | tr '_' ' '`
				name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
				addResult "disable-$file" "disable-$file" "Disable \"$name\"" "" "icons/pause.png" "yes" "disable \"$name\""
			fi
		done
		if [ "$yes" = 'false' ]; then
			addResult '' '' 'There are no enabled cron jobs.' '' 'icons/warning.png' 'no' ''
		fi
	fi
elif [[ "$arg" =~ ^en ]]; then
	count=0
	dir=`find "$scriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		for f in "$scriptDir/"*
			do
			if [ -f "$f" ]; then
				file=$(basename "$f")
				if [ ! -e "$enabledScriptDir/$file" ]; then
					count=$((count+1))
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "enable-$file" "enable-$file" "Enable \"$name\"" "" "icons/play.png" "yes" "enable \"$name\""
				fi
			fi
		done
		if [[ $count = 0 ]]; then
			addResult '' '' 'All cron jobs are enabled.' "" 'icons/warning.png' 'no' ''
		fi
	else
		addResult '' '' 'No cron jobs have been defined.' "" 'icons/warning.png' 'no' ''
	fi
elif [[ "$arg" =~ ^de ]]; then
	dir=`find "$scriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		for f in "$scriptDir/"*
			do
			if [ -f "$f" ]; then
				file=$(basename "$f")
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "delete-$file" "delete-$file" "Delete \"$name\"" "" "icons/bin.png" "yes" "delete \"$name\""
			fi
		done
	else
		addResult '' '' 'No cron jobs have been defined.' "" 'icons/warning.png' 'no' ''
	fi
elif [[ "$arg" =~ ^er ]]; then
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'Alfred Cron' "All scripts are running just fine." 'icons/square_ok.png' 'no' ''
	else
		addResult '' '' 'There are errors in some scripts.' "All error scripts have been disabled. Please debug them." 'icons/warning.png' 'no' ''
		for f in "$errorDir/"*
		do
		if [ -f "$f" ]; then
				file=$(basename "$f")
				if [ -f "$errorDir/$file" ]; then
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "clear-$file" "clear-$file" "\"$name\" has errors" "Clear this error warning." "icons/record.png" "yes" "error clear \"$name\""
				fi
			fi
		done
		addResult "cronclearallerrors" "clear-all" "Clear all errors." "" "icons/loading.png" "yes" "error clear all"
	fi
# To implement a launchd script to start the agent running. Currently, not all of it is working, so it's commented out for initial release
# elif [[ "$arg" =~ ^inst ]]; then
# 	if [ -e "$HOME/Library/LaunchDaemons/com.alfred.cron.plist" ]; then
# 		addResult "" "" "The launchd agent has already been installed." "" "icons/warning.png" "no" ""
# 	else
# 		addResult "launchdstatus" "installlaunchd-user" "Install the launchd agent for this user" "Cron" "icons/warning.png" "yes" "installlaunchd-user"
# 	fi
else
	if [ "$running" = "FALSE" ]; then
		addResult "" "" "Cron is off" "Cron status" "icons/warning.png" "yes" "status"
		addResult "startcron" "start" "Start Cron" "Cron" "icons/circle_play.png" "yes" "start"
	else
		pid=`cat "$pidFile"`
		addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/square_ok.png" "yes" "status"
		addResult "stopcron" "stop" "Pause Cron" "Cron" "icons/circle_pause.png" "yes" "stop"
	fi
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		addResult 'cronerrors' 'error' 'There are errors in some scripts.' "All scripts with errors have been disabled. Please debug them." 'icons/warning.png' 'no' 'error'
	fi
	# To implement a launchd script to start the agent running. Currently, not all of it is working, so it's commented out for initial release
	# if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
	# 	addResult "launchdstatus" "uninstallinstalllaunchd-user" "Alfred Cron will start at user login" "Cron" "icons/check-green.png" "no" "uninstalllaunchd"
	# else
	# 	addResult "installlaunchd" "installlaunchd" "The launchd agent has not been installed." "Cron" "icons/warning.png" "no" "installlaunchd"
	# fi
	addResult "addcronjob" "add" "Add a Cron Entry" "Cron" "icons/circle_plus.png" "yes" "add"
	addResult "listcronjobs" "" "List Cron Jobs" "Cron" "icons/hashtag.png" "no" "list"
fi
# Print the results
getXMLResults
