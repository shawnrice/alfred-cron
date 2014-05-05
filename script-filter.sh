#!/bin/bash

path="$( cd "$(dirname "$0")" ; pwd -P )"

. "$path/variables"
. "$path/setup.sh"
. "$BashWorkflowHandler"
"$path/SetupIconsForTheme"

running=`"$path/alfred-cron.sh" check`

# For the Icons
if [ -e 'icon-dark.png' ]; then
	suffix='-light.png'
else
	suffix='.png'
fi

# Test to see if there is an argument.
if [ ! -z "$1" ]; then
	arg="$1"
fi

# Split the argument
if [[ "$arg" =~ " " ]]; then
	second=`echo "$arg" | awk '{split($0,array," ")} END{print array[2]}'`
	arg=`echo "$arg" | awk '{split($0,array," ")} END{print array[1]}'`
fi

################################################################################
# List and Edit are treated the same
################################################################################
if [[ "$arg" =~ ^li ]] || [[ "$arg" =~ ^ed ]]; then
	dir=`find "$scriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'No cron jobs have been defined.' "$count" "icons/warning$suffix" 'no' ''
	else
		for f in "$scriptDir/"*
		do
			if [ -f "$f" ]; then
				file=$(basename "$f")
				name=`echo $file | tr '_' ' '`
				name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
				if [ -e "$enabledScriptDir/$file" ]; then
						icon="icons/circle_ok$suffix"
				else
					icon="icons/circle$suffix"
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

################################################################################
# Disable Job
################################################################################
elif [[ "$arg" =~ ^di ]]; then
	dir=`find "$enabledScriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	# echo $dir
	if [ -z "$dir" ]; then
		addResult '' '' 'There are no enabled cron jobs.' '' "icons/warning$suffix" 'no' ''
	else
		yes='false'
		for f in "$enabledScriptDir/"*
		do
			file=$(basename "$f")
			if [ ! "$file" = "*" ]; then
				yes='true'
				name=`echo $file | tr '_' ' '`
				name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
				addResult "disable-$file" "disable-$file" "Disable \"$name\"" "" "icons/pause$suffix" "yes" "disable \"$name\""
			fi
		done
		if [ "$yes" = 'false' ]; then
			addResult '' '' 'There are no enabled cron jobs.' '' "icons/warning$suffix" 'no' ''
		fi
	fi

################################################################################
# Enable Job
################################################################################
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
					addResult "enable-$file" "enable-$file" "Enable \"$name\"" "" "icons/play$suffix" "yes" "enable \"$name\""
				fi
			fi
		done
		if [[ $count = 0 ]]; then
			addResult '' '' 'All cron jobs are enabled.' "" "icons/warning$suffix" 'no' ''
		fi
	else
		addResult '' '' 'No cron jobs have been defined.' "" "icons/warning$suffix" 'no' ''
	fi

################################################################################
# Delete Job
################################################################################
elif [[ "$arg" =~ ^de ]]; then
	dir=`find "$scriptDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		for f in "$scriptDir/"*
			do
			if [ -f "$f" ]; then
				file=$(basename "$f")
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "delete-$file" "delete-$file" "Delete \"$name\"" "" "icons/bin$suffix" "yes" "delete \"$name\""
			fi
		done
	else
		addResult '' '' 'No cron jobs have been defined.' "" "icons/warning$suffix" 'no' ''
	fi

################################################################################
# View Errors
################################################################################
elif [[ "$arg" =~ ^er ]]; then
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ -z "$dir" ]; then
		addResult '' '' 'Alfred Cron' "All scripts are running just fine." "icons/square_ok$suffix" 'no' ''
	else
		addResult '' '' 'There are errors in some scripts.' "All error scripts have been disabled. Please debug them." "icons/warning$suffix" 'no' ''
		for f in "$errorDir/"*
		do
		if [ -f "$f" ]; then
				file=$(basename "$f")
				if [ -f "$errorDir/$file" ]; then
					name=`echo $file | tr '_' ' '`
					name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
					addResult "clear-$file" "clear-$file" "\"$name\" has errors" "Clear this error warning." "icons/record$suffix" "yes" "error clear \"$name\""
				fi
			fi
		done
		addResult "cronclearallerrors" "clear-all" "Clear all errors." "" "icons/loading$suffix" "yes" "error clear all"
	fi

################################################################################
# Start / Stop / Status
################################################################################
elif [[ "$arg" =~ ^s ]]; then
	##### Start
	if [[ "$arg" =~ ^star ]]; then
		if [ "$running" = "FALSE" ]; then
			addResult "startcron" "start" "Start Cron" "Cron" "icons/circle_play$suffix" "yes" "start"
		else
			pid=`cat "$pidFile"`
			addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/square_ok$suffix" "yes" "status"
		fi
	##### Status
	elif [[ "$arg" =~ ^stat ]]; then
		if [ "$running" = "FALSE" ]; then
			addResult "" "" "Cron is off" "Cron status" "icons/warning$suffix" "yes" "status"
		else
			pid=`cat "$pidFile"`
			addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/square_ok$suffix" "yes" "status"
		fi
	##### Stop
	elif [[ "$arg" =~ ^sto ]]; then
		if [ "$running" = "FALSE" ]; then
			addResult "" "" "Cron is off" "Cron status" "icons/warning$suffix" "yes" "status"
		else
			addResult "stopcron" "stop" "Stop Cron" "Cron" "icons/circle_stop$suffix" "yes" "stop"
		fi
	##### Start / Stop / Status
	else
		if [ "$running" = "FALSE" ]; then
			addResult "" "" "Cron is off" "Cron status" "icons/warning$suffix" "yes" "status"
			addResult "startcron" "start" "Start Cron" "Cron" "icons/circle_play$suffix" "yes" "start"
		else
			pid=`cat "$pidFile"`
			addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/square_ok$suffix" "yes" "status"
			addResult "stopcron" "stop" "Stop Cron" "Cron" "icons/circle_stop$suffix" "yes" "stop"
		fi
	fi

################################################################################
# Add Job
################################################################################
elif [[ "$arg" =~ ^a ]]; then
	addResult "addcronjob" "add" "Add a Cron Entry" "Cron" "icons/circle_plus$suffix" "yes" "add"

################################################################################
# View Log
################################################################################
elif [[ "$arg" =~ ^lo ]]; then
	addResult "viewlog" "log" "View Cron Log" "Open the log in your default text application" "" "yes" "log"

################################################################################
# Install LaunchAgent
################################################################################
elif [[ "$arg" =~ ^i ]]; then
	if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
		launch=$(launchctl list|grep "Alfred Cron")
		if [ -z "$launch" ]; then
			addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
		else
			addResult "launchdstatus" "uninstall" "Alfred Cron will start at user login" "Select to uninstall the launchd agent" "icons/square_ok$suffix" "yes" "uninstall"
		fi
	else
		addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
	fi

################################################################################
# Uninstall LaunchAgent
################################################################################
elif [[ "$arg" =~ ^u ]]; then
	if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
		launch=$(launchctl list|grep "Alfred Cron")
		if [ ! -z "$launch" ]; then
			addResult "launchdstatus" "uninstall" "Alfred Cron will start at user login" "Select to uninstall the launchd agent" "icons/square_ok$suffix" "yes" "uninstall"
		else
			addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
		fi
	else
		addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
	fi
################################################################################
# No Argument / Unrecognized One
################################################################################
else
	if [ "$running" = "FALSE" ]; then
		addResult "" "" "Cron is off" "Cron status" "icons/warning$suffix" "yes" "status"
		addResult "startcron" "start" "Start Cron" "Cron" "icons/circle_play$suffix" "yes" "start"
	else
		pid=`cat "$pidFile"`
		addResult "" "" "Cron is running with PID: $pid" "Cron status" "icons/square_ok$suffix" "yes" "status"
		addResult "stopcron" "stop" "Stop Cron" "Cron" "icons/circle_stop$suffix" "yes" "stop"
	fi
	dir=`find "$errorDir/" -type f -maxdepth 1 | sed s,^./,,`
	if [ ! -z "$dir" ]; then
		addResult 'cronerrors' 'error' 'There are errors in some scripts.' "All scripts with errors have been disabled. Please debug them." "icons/warning$suffix" 'no' 'error'
	fi
	addResult "addcronjob" "add" "Add a Cron Entry" "Cron" "icons/circle_plus$suffix" "yes" "add"
	addResult "listcronjobs" "" "List Cron Jobs" "Cron" "icons/hashtag$suffix" "no" "list"
	# To implement a launchd script to start the agent running.
	if [ -e "$HOME/Library/LaunchAgents/com.alfred.cron.plist" ]; then
		launch=$(launchctl list|grep "Alfred Cron")
		if [ ! -z "$launch" ]; then
			addResult "launchdstatus" "uninstall" "Alfred Cron will start at user login" "Select to uninstall the launchd agent" "icons/square_ok$suffix" "yes" "uninstall"
		else
			addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
		fi
	else
		addResult "install" "install" "The launchd agent has not been installed." "Install the lauchd agent to start Alfred Cron automatically" "icons/warning$suffix" "yes" "install"
	fi
	addResult "viewlog" "log" "View Cron Log" "Open the log in your default text application" "" "yes" "log"
fi

# Print the results
getXMLResults
