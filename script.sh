#!/bin/bash

path="$( cd "$(dirname "$0")" ; pwd -P )"
# This is the intermediary script.
. "$path/variables"

log() {
	# Generic log function.
	echo "$1" > "$cache/tmpRunFile"
	cat "$logFile" >> "$cache/tmpRunFile"
	mv "$cache/tmpRunFile" "$logFile"
}

query="$1"
now=`date +'%Y-%m-%d  %H:%M:%S'`

################################################################################
# Daemon Controls
################################################################################
if [ "$query" = "start" ]; then
	launch=$(launchctl list|grep "Alfred Cron")
	if [ ! -z "$launch" ]; then
		launchctl start "Alfred Cron"
		echo "The daemon is now running."
	else
		nohup "$path/alfred-cron.sh" start > /dev/null 2>&1 &
		echo "The daemon is now running."
	fi
elif [ "$query" = "stop" ]; then
	launch=$(launchctl list|grep "Alfred Cron")
	if [ ! -z "$launch" ]; then
		launchctl stop "Alfred Cron"
		echo "The daemon has stopped."
		running=`"$path/alfred-cron.sh" check`
		if [ "$running" != "False" ]; then
			"$path/alfred-cron.sh" stop > /dev/null 2>&1
		fi
	else
		"$path/alfred-cron.sh" stop > /dev/null 2>&1
		echo "The daemon has stopped."
	fi

################################################################################
# Job Controls
################################################################################

##### Add
elif [ "$query" = "add" ]; then
	"$path/manage.sh"

##### Enable
elif [[ "$query" =~ enable ]]; then
	script=${query#enable-}
	ln "$scriptDir/$script" "$enabledScriptDir/$script"
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	echo "\"$name\" has been enabled."
	log "*** $now: \"$name\" has been enabled."

##### Disable
elif [[ "$query" =~ disable ]]; then
	script=${query#disable-}
	rm "$enabledScriptDir/$script"
	name=`echo $script | tr '_' ' '`
	name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
	echo "\"$name\" has been disabled."
	log "*** $now: \"$name\" has been disabled."

##### Edit
elif [[ "$query" =~ edit ]]; then
	script=${query#edit-}
	"$path/manage.sh 'edit' '$script' '$scriptDir/$script'"

##### Delete
elif [[ "$query" =~ delete ]]; then
	script=${query#delete-}
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

################################################################################
# Error Controls
################################################################################
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

################################################################################
# LaunchAgent
################################################################################

##### Install
elif [[ "$query" =~ ^install ]]; then
	if [ ! -d "$data/assets" ]; then
		mkdir "$data/assets"
	fi
	if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
		rm "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
	fi
	if [ ! -f 'assets/com.alfred.cron.plist' ]; then
		echo "Cannot find launchd template in workflow directory. Aborting."
		exit 1
	else
		if [ -f "$data/assets/com.alfred.cron.plist" ]; then
			rm "$data/assets/com.alfred.cron.plist"
		fi
		echo $(cat 'assets/com.alfred.cron.plist' | sed 's|REPLACE_ALFRED_CRONPATH|'"$path/alfred-cron.sh"'|g') > "$data/assets/com.alfred.cron.plist"
	fi
	running=`$path/alfred-cron.sh check`
	if [ "$running" = 'TRUE' ]; then
		"$path/alfred-cron.sh stop > /dev/null 2>&1 &"
	fi
	ln "$data/assets/com.alfred.cron.plist" "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
	launchctl load "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
	launchctl start "Alfred Cron"
	echo "Alfred Cron is running and will now start at login."

##### Uninstall
elif [[ "$query" =~ ^uninstall ]]; then
	launch=`launchctl list|grep "Alfred Cron"`
	running=`"$path/alfred-cron.sh" check`
	if [ ! -z "$launch" ]; then
		launchctl stop "Alfred Cron"
		launchctl unload "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
	fi
	if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
		rm "$HOME/Library/LaunchAgents/com.alfred.cron.plist"
	fi
	echo "Alfred Cron will no longer start at login."
	if [ "$running" = 'TRUE' ]; then
		# Since Cron was running beforehand, we'll just start it up again.
		nohup "$path/alfred-cron.sh" start > /dev/null 2>&1 &
	fi

################################################################################
# Logs
################################################################################

elif [[ "$query" =~ ^lo ]]; then
	if [ -e "$logFile" ]; then
		qlmanage -p "$logFile" > /dev/null 2>&1 &
		# open "$logFile"
	fi
else
	echo "Invalid command $query"
fi
