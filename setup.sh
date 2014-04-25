#!/bin/sh

. variables

dir() {
  if [ ! -d "$1" ]; then
    mkdir "$1"
  fi
}

dir "$cache"
dir "$data"
dir "$logDir"
dir "$scriptDir"
dir "$enabledScriptDir"
dir "$errorDir"
dir "$data/assets"

if [ ! -f "alfred.bundler.sh" ]; then
  curl -sL "https://raw.githubusercontent.com/shawnrice/alfred-bundler/aries/wrappers/alfred.bundler.sh" > alfred.bundler.sh
fi

# Copy the daemon to the datadir
# Copy the launchd plist to the datadir

. alfred.bundler.sh

BashWorkflowHandler=`__load BashWorkflowHandler`

if [ ! -f "$pashuapath" ]; then
  Pashua=`__load Pashua default utility`
fi

if [ ! -f "$tn" ]; then
  tn=`__load terminal-notifier default utility`
fi