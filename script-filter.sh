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
		addResult '' '' 'No cron jobs have been defined.' "$count" 'icons/warning-yellow.png' 'no' ''
	else
		for f in "$scriptDir/"*
		do			
			if [ -f "$f" ]; then
				file=$(basename "$f")
				if [ -e "$enabledScriptDir/$file" ]; then
					icon='icons/radio-on-blue.png'
				else
					icon='icons/radio-off-blue.png'
				fi
				if [ ! -z "$second" ]; then
					if [[ "$file" =~ "$second" ]]; then
						addResult "edit-$file" "edit-$file" "Edit $file" "$second" "$icon" "yes" "edit-$file"
					fi
				else
					if [[ `echo $icon | grep '\-on\-'` ]]; then
						addResult "edit-$file" "edit-$file" "Edit $file" "Job Enabled" "$icon" "yes" "edit-$file"
					else
						addResult "edit-$file" "edit-$file" "Edit $file" "Job Disabled" "$icon" "yes" "edit-$file"
					fi
				fi
			fi
		done
	fi
elif [[ "$arg" =~ ^di ]]; then
	dir=`find "$enabledScriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'There are no enabled cron jobs.' '' 'icons/warning-yellow.png' 'no' ''
	else
		for f in "$enabledScriptDir/"*
		do
			file=$(basename "$f")
			name=`echo $file | tr '_' ' '`
			name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
			addResult "disable-$file" "disable-$file" "Disable \"$name\"" "" "icons/pause-green.png" "yes" "disable \"$name\""
		done
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
					addResult "enable-$file" "enable-$file" "Enable \"$name\"" "" "icons/green-play.png" "yes" "enable \"$name\""
				fi
			fi
		done
		if [[ $count = 0 ]]; then
			addResult '' '' 'All cron jobs are enabled.' "" 'icons/warning-yellow.png' 'no' ''	
		fi
	else
		addResult '' '' 'No cron jobs have been defined.' "" 'icons/warning-yellow.png' 'no' ''
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
					addResult "delete-$file" "delete-$file" "Delete \"$name\"" "" "icons/minus-red.png" "yes" "delete \"$name\""
			fi
		done
	else
		addResult '' '' 'No cron jobs have been defined.' "" 'icons/warning-yellow.png' 'no' ''
	fi	
elif [[ "$arg" =~ ^er ]]; then
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'Alfred Cron' "All scripts are running just fine." 'icons/box-check-green.png' 'no' ''
	else
		addResult '' '' 'There are errors in some scripts.' "All error scripts have been disabled. Please debug them." 'icons/exclamation-red.png' 'no' ''
		for f in "$errorDir/"*
		do
		if [ -f "$f" ]; then
				file=$(basename "$f")
				if [ -f "$errorDir/$file" ]; then
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "clear-$file" "clear-$file" "\"$name\" has errors" "Clear this error warning." "icons/warning-yellow.png" "yes" "error clear \"$name\""
				fi
			fi
		done
		addResult "cronclearallerrors" "clear-all" "Clear all errors." "" "icons/refresh-yellow.png" "yes" "error clear all"
	fi
else
	if [ "$running" = "FALSE" ]; then
		addResult "" "" "Cron is off" "Cron status" "icons/warning-yellow.png" "yes" "status"
		addResult "startcron" "start" "Start Cron" "Cron" "icons/on-green.png" "yes" "start"
	else
		pid=`cat "$pidFile"`
		addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/box-check-green.png" "yes" "status"
		addResult "stopcron" "stop" "Stop Cron" "Cron" "icons/delete-red.png" "yes" "stop"
	fi
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		addResult 'cronerrors' 'error' 'There are errors in some scripts.' "All scripts with errors have been disabled. Please debug them." 'icons/exclamation-red.png' 'no' 'error'
	fi
	addResult "addcronjob" "add" "Add a Cron Entry" "Cron" "icons/plus-green.png" "yes" "add"
fi
# Print the results
getXMLResults