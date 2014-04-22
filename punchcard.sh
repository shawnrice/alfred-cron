#!/bin/bash
. variables

runCommand() {
 if [ -z "$3" ]; then
  run="never"
 else
  run="$3"
 fi
 echo "" >> "$logFile"
 echo "----------------------------------------------------------------------" >> "$logFile"
 echo `date +'%Y-%m-%d  %H:%M:%S'`": Running $1 (every $2 seconds) and was last run $run." >> "$logFile"
 sh "$enabledScriptDir/$1" >> "$logFile"
 if [ -f "$data/punchcard" ]; then
  awk '!/'"$name"'/' "$data/punchcard" > "$cache/punchcard" && mv "$cache/punchcard" "$data/punchcard"
 fi
 echo "$1=$now" >> "$data/punchcard"
 echo "----------------------------------------------------------------------" >> "$logFile"
}

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