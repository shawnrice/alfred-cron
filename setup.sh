#!/bin/sh

. variables

test_connection() {
  ping -c 1 -t 2 -q www.google.com > /dev/null 2>&1

  if [ 0 -eq $? ]; then
    echo 1
  else
    echo 0
  fi
}

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

. alfred.bundler.sh

# Even though the bash library should be downloaded, and all we really need is
# the path, we're leaving this call here so as to allow the bundler to check
# for updates for itself.
BashWorkflowHandler=`__load BashWorkflowHandler`

# Neither of these should matter because we should have them installed when
# we do the first-run, but we'll leave them here for redundancy.
if [ ! -f "$pashuapath" ]; then
  Pashua=`__load Pashua default utility`
fi
if [ ! -f "$tn" ]; then
  tn=`__load terminal-notifier default utility`
fi
