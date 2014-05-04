#!/bin/sh

. variables

check() {
  # Basically, if the directories or anything is missing, then we'll install
  # the dependencies
  if [ ! -d "$1" ]; then
    if [ -f "$data/assets/setup-complete" ]; then
      rm "$data/assets/setup-complete"
    fi
    ./first-run.sh
    exit
  fi
}

check "$cache"
check "$data"
check "$logDir"
check "$scriptDir"
check "$enabledScriptDir"
check "$errorDir"
check "$data/assets"

if [ ! -f "alfred.bundler.sh" ]; then
  curl -sL "https://raw.githubusercontent.com/shawnrice/alfred-bundler/aries/wrappers/alfred.bundler.sh" > alfred.bundler.sh
fi

# script : "tell application \"Alfred 2\" to run trigger \"com.alfred.cron\" in workflow \"alfred.cron.spr\" with argument \"test\""

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
