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
	# "$data/assets"
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
	echo "here"
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	applescripticon="$(echo `pwd`/icons/warning.png | tr '/' ':' | awk '{print substr($0, 2, length($0) - 1)}')"
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
		echo "Deleted job: \"$name\""
	fi
# To implement a launchd script to start the agent running. Currently, not all of it is working, so it's commented out for initial release
# elif [[ "$query" =~ ^install ]]; then
# 	if [ ! -d "$data/assets" ]; then
# 		mkdir "$data/assets"
# 	fi
# 	if [ ! -f 'assets/com.alfred.cron.plist' ]; then
# 		echo "Cannot find launchd template in workflow directory. Aborting."
# 		exit 1
# 	else
# 		me=`pwd`
# 		if [ -f "$data/assets/com.alfred.cron.plist" ]; then
# 			rm "$data/assets/com.alfred.cron.plist"
# 		fi
# 		echo $(cat 'assets/com.alfred.cron.plist' | sed 's|REPLACE_ALFRED_CRONPATH|'"$me/alfred-cron.sh"'|g') > "$data/assets/com.alfred.cron.plist"
# 	fi
# 		# script="chown $USER '$data/assets/com.alfred.cron.plist'"
# 		# osascript -e "do shell script \"$script\" with administrator privileges"
# 		ln "$data/assets/com.alfred.cron.plist" "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
# 		script="launchctl load '$HOME/Library/LaunchAgents/com.alfred.cron.plist'"
# 		osascript -e "do shell script \"$script\" with administrator privileges"
# elif [[ "$query" =~ ^uninstall ]]; then
# 	if [ -e "/Library/LaunchDaemons/com.alfred.cron.plist" ]; then
# 		script="launchctl unload '/Library/LaunchDaemons/com.alfred.cron.plist'"
# 		osascript -e "do shell script \"$script\" with administrator privileges"
# 		script="rm '/Library/LaunchDaemons/com.alfred.cron.plist'"
# 		osascript -e "do shell script \"$script\" with administrator privileges"
# 	fi
# 	if [ -e "$HOME/Library/LaunchDaemons/com.alfred.cron.plist" ]; then
# 		launchctl unload "$HOME/Library/LaunchDaemons/com.alfred.cron.plist"
# 		rm "$HOME/Library/LaunchDaemons/com.alfred.cron.plist"
# 	fi
else
	echo "Invalid command $query"
fi
