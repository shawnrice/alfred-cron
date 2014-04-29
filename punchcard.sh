#!/bin/bash
. variables
. alfred.bundler.sh

runCommand() {
 if [ -z "$3" ]; then
  run="never"
 else
  t=`date +"%s"`
  run="$3"
  run=$((t-run))
  run="$run seconds ago"
 fi
 echo "-----" > "$cache/tmpRunFile"
 echo `date +'%Y-%m-%d  %H:%M:%S'`": Running $1 (every $2 seconds) and was last run $run." >> "$cache/tmpRunFile"
 output=`sh "$enabledScriptDir/$1"`
 error=`echo $?`
 if [[ ! $error -eq 0 ]]; then
  echo "Error code: $error" > "$errorDir/$1"
  echo "!!! Error code $error when running $1."  >> "$cache/tmpRunFile"
  echo "!!! $1 has been disabled." >> "$cache/tmpRunFile"
  echo "$output" >> "$errorDir/$1"
  rm "$enabledScriptDir/$1"
  tn=`__load Terminal-Notifier default utility`
  name=`echo $1 | tr '_' ' '`
  name=`echo "$name" | awk '{for(i=1;i<=NF;i++){sub(".",substr(toupper($i),1,1),$i)}print}'`
  icon=`pwd`"/icons/alert.ico"
  "$tn" -title 'Alfred Cron Error' \
     -subtitle "Job: \"$name.\"" \
     -message "The job has been disabled." \
     -execute "osascript -e 'tell application \"Alfred 2\" to search \"cron er\"'" \
     -appIcon "$icon" \
     -group alfredcron
 fi
 echo "$output" >> "$cache/tmpRunFile"
 cat "$logFile" >> "$cache/tmpRunFile"
 mv "$cache/tmpRunFile" "$logFile"
 if [ -f "$data/punchcard" ]; then
  awk '!/'"$name"'/' "$data/punchcard" > "$cache/punchcard" && mv "$cache/punchcard" "$data/punchcard"
 fi
 echo "$1=$now" >> "$data/punchcard"
} # runCommand



now=`date +'%s'`
if [ -f "$data/registry" ]; then
 registry=`cat "$data/registry"`
fi

if [ -f "$data/punchcard" ]; then
 punchcard=`cat "$data/punchcard"`
fi

if [ ! -z "$registry" ]; then
 for line in $registry
 do
  while IFS='=' read -ra parts; do
   name="${parts[0]}"
   interval="${parts[1]}"
   if [ -f "$enabledScriptDir/$name" ]; then
    if [[ -z `echo $punchcard | grep "$name"` ]]; then
     runCommand "$name" "$interval"
    elif [[ `echo $punchcard | grep "$name"` ]]; then
     last=$(echo "$punchcard" | egrep -o "$name=[[:digit:]]*" | head -n1 | tr -cd '[[:digit:]]')
     if [[ $((last+interval)) -lt $now ]]; then
       runCommand "$name" "$interval" "$last"
     fi
    fi
   fi
  done <<< "$line"
 done
fi
