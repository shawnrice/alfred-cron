#!/bin/bash
. variables

if [ "$1" = "edit" ]  && [ ! -z "$2" ] && [ -f "$scriptDir/$2" ]; then
	timeDefault="120"
	pDefault="Seconds"
	
	dTitle="Modify Alfred Cron Entry"

	# Let's actually reset the time/interval if one exists in the registry
	if [ -f "$data/registry" ]; then
		registry=`cat "$data/registry" | grep "$2"`
		while IFS='=' read -ra parts; do
			interval="${parts[1]}"
		done <<< "$registry"

		m=60
		h=$((m*60))
		d=$((h*24))
		w=$((d*7))

		if [[ $((interval%w)) -eq 0 ]]; then
			timeDefault=$((interval/w))
			pDefault='Weeks'
		elif [[ $((interval%d)) -eq 0 ]]; then
			timeDefault=$((interval/d))
			pDefault='Days'
		elif [[ $((interval%h)) -eq 0 ]]; then
			timeDefault=$((interval/h))
			pDefault='Hours'
		elif [[ $((interval%m)) -eq 0 ]]; then
			timeDefault=$((interval/m))
			pDefault='Minutes'
		else
			timeDefault="$interval"
			pDefault='Seconds'
		fi
	fi
	nameDefault="$2"
	commandDefault=`cat "$scriptDir/$2" | awk 1 ORS='[return]'`
else
	dTitle="Add Alfred Cron Entry"
	nameDefault="My Entry Label"
	timeDefault="120"
	pDefault="Seconds"
	commandDefault=""
fi

pashua_run() {
	pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
	echo "$1" > $pashua_configfile
	
	if [ ! "$pashuapath" ]
	then
		echo "Error: Pashua could not be found"
		exit 1
	fi

	# Manage encoding
	if [ "$2" = "" ]
	then
		encoding=""
	else
		encoding="-e $2"
	fi

	# Get result
	result=$("$pashuapath" $encoding $pashua_configfile | perl -pe 's/ /;;;/g;')

	# Remove config file
	rm $pashua_configfile

	# Parse result
	for line in $result
	do
		key=$(echo $line | sed 's/^\([^=]*\)=.*$/\1/')
		value=$(echo $line | sed 's/^[^=]*=\(.*\)$/\1/' | sed 's/;;;/ /g')
		varname=$key
		varvalue="$value"
		eval $varname='$varvalue'
	done

} # pashua_run()

trim() {
	
	# if [[ $1 =~ \[return\]\[return\] ]]; then
	# 	trim `echo "$1" | sed -e 's|\[return\]\[return\]|\[return\]|g'`
	if [[ "$1" =~ \[return\]$ ]]; then
		trim "${1%\[return]}"
	elif [[ "$1" =~ ^\[return\] ]]; then
		trim "${1#\[return]}"
	else
		echo $1
	fi
}

conf="
*.transparency=0.95

*.title = $dTitle

# Label
name.type = textfield
name.label = Label
name.default = My Entry Label
name.width = 360

# Add Time
time.type = textfield
time.label = Execution Interval
time.default = $timeDefault
time.width = 40

# Add Units
p.type = popup
p.width = 80
p.x = 50
p.y = 287
p.option = Seconds
p.option = Minutes
p.option = Hours
p.option = Days
p.option = Weeks
p.default = $pDefault

# Commands
command.type = textbox
command.width = 600
command.height = 200
command.default = $commandDefault
command.label = Shell Command to Execute (you can use standard shell variables)

# Add a cancel button with default label
cb.type=cancelbutton
"
icon='icon.png'

if [ -e "$icon" ]
then
	# Display Pashua's icon
	conf="$conf
	     img.type = image
	     img.x = 472
	     img.y = 270
			 img.border = 1
			 img.maxwidth = 128
	     img.path = $icon"
fi

pashua_run "$conf" 'utf8'

if [ "$cb" = "1" ]; then
	echo "FALSE"
elif [ -z "$name" ]; then
	echo "FALSE"
elif [ -z "$time" ]; then
	echo "FALSE"
elif [ -z "$command" ]; then
	echo "FALSE"
else
	name=`echo "$name" | \
	tr '[:upper:]' '[:lower:]' | \
	sed -E 's|[^a-zA-Z0-9\-]+|_|g'`
	
	case $p in
		Seconds)
			interval=$time
		;;
		Minutes)
			interval=$((time*60))
		;;
		Hours)
			interval=$((time*60*60))
		;;
		Days)
			interval=$((time*60*60*24))
		;;
		Weeks)
			interval=$((time*60*60*24*7))
		;;
	esac
	
	if [ -f "$scriptDir/$name" ]; then
		echo "Error: Script already exists."
		exit 1
	fi

	# Save the script.
	echo "#!/bin/bash[return]set -o errexit[return]"`trim "$command"` | \
	 sed -e 's|^ *||' \
	     -e 's| *$||' \
			 -e 's|\[return\]|\'$'\n|g' > "$scriptDir/$name"
	
	# Delete an entry if the name is already in there. This error should already
	# have been accounted for.
	awk '!/'"$name"'/' "$data/registry" > "$cache/registry" && mv "$cache/registry" "$data/registry"
	echo "$name"="$interval" >> "$data/registry"

	# Enable the script
	ln "$scriptDir/$name" "$enabledScriptDir/$name"
fi
