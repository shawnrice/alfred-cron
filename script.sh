#!/bin/bash

# This is the intermediary script.
. variables

log() {
	# Generic log function.
	echo "$1" > "$cache/tmpRunFile"
	cat "$logFile" >> "$cache/tmpRunFile"
	mv "$cache/tmpRunFile" "$logFile"
}

query="$1"
now=`date +'%Y-%m-%d  %H:%M:%S'`
if [ "$query" = "start" ]; then
	nohup sh alfred-cron.sh start > /dev/null 2>&1 &
	echo "The daemon is now running."
elif [ "$query" = "stop" ]; then
	./alfred-cron.sh stop > /dev/null 2>&1
	echo "The daemon has stopped."
elif [ "$query" = "add" ]; then
	sh manage.sh
elif [[ "$query" =~ enable ]]; then
	script=${query#enable-}
	ln "$scriptDir/$script" "$enabledScriptDir/$script"
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	echo "\"$name\" has been enabled."
	log "*** $now: \"$name\" has been enabled."
elif [[ "$query" =~ disable ]]; then
	script=${query#disable-}
	rm "$enabledScriptDir/$script"
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	echo "\"$name\" has been disabled."
	log "*** $now: \"$name\" has been disabled."
elif [[ "$query" =~ edit ]]; then
	script=${query#edit-}
	sh manage.sh "edit" "$script" "$scriptDir/$script"
	log "*** $now: Cleared errors for \"$name.\""
elif [[ "$query" =~ clear ]]; then
	script=${query#clear-}
	if [ "$script" = "all" ]; then
		rm "$errorDir/"*
		echo "All errors have been cleared. Please re-enable your jobs."
		log "*** $now: All errors have been cleared."
	else
		rm "$errorDir/$script"
		name=`echo $script | tr '_' ' '`
		name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
		echo "The error for $name has been removed. Please re-enable it."
		log "*** $now: Errors for \"$name\" have been cleared."
	fi
elif [[ "$query" =~ delete ]]; then
	script=${query#delete-}
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	applescripticon="$(echo `pwd`/icons/alert.icns | tr '/' ':' | awk '{print substr($0, 2, length($0) - 1)}')"
	read -d '' applescript <<-"_EOF_"
display dialog "Do you really want to delete 'JOBNAME'?" buttons {"Confirm", "Cancel"} default button 1 cancel button 2 with title "Alfred Cron" with icon file "ICONFILE"
	_EOF_
	applescript=`echo "$applescript" | sed 's|ICONFILE|'"$applescripticon"'|g'`
	applescript=`echo "$applescript" | sed 's|JOBNAME|'"$name"'|g'`
	response=`osascript -e "$applescript"`
	if [ ! -z "$response" ]; then
		if [ -e "$enabledScriptDir/$script" ]; then
			rm "$enabledScriptDir/$script"
		fi
		if [ -e "$errorDir/$script" ]; then
			rm "$errorDir/$script"
		fi
		rm "$scriptDir/$script"
		echo "Deleted job: $name"
	fi
else
	echo "Invalid command $query"
fi