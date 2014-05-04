#!/bin/sh

# This script is run in the background, and nothing is passed back to Alfred,
# so all output will be available to a debugger, at best.

test_connection() {
  ping -c 1 -t 2 -q www.google.com > /dev/null 2>&1

  if [ 0 -eq $? ]; then
    echo 1
  else
    echo 0
  fi
}

dir() {
  if [ ! -d "$1" ]; then
    mkdir "$1"
  fi
}

. variables

# First, let's make our directories if not there.
dir "$cache"
dir "$data"
dir "$logDir"
dir "$scriptDir"
dir "$enabledScriptDir"
dir "$errorDir"
dir "$data/assets"

# Second, let's check the internet connection.
if [ ! `test_connection` -eq 1 ]; then
  echo "Error: No Internet connection."
  exit 1
fi

# Okay, we have an internet connection, so we'll start this sucker up.
./check-setup.sh &> /dev/null
tmpPID=`echo $$`

# Third, let's download the bundler wrapper if it isn't there.
if [ ! -f "alfred.bundler.sh" ]; then
  curl -sL "https://raw.githubusercontent.com/shawnrice/alfred-bundler/aries/wrappers/alfred.bundler.sh" > alfred.bundler.sh
  if [ `echo $?` -ne 0 ]; then
    echo "Error: Couldn't get the Bundler Wrapper."
    kill -9 "$tmpPID"
    exit 1
  fi
fi

# Include the bundler wrapper now that we know it's there.
. alfred.bundler.sh

# Fourth, load/download the BashWorkflowHandler.
BashWorkflowHandler=`__load BashWorkflowHandler`
if [ `echo $?` -ne 0 ]; then
  echo "Error: Couldn't load BashWorkflowHandler."
  kill -9 "$tmpPID"
  exit 1
fi

# Fifth, load/download the BashWorkflowHandler.
if [ ! -f "$pashuapath" ]; then
  Pashua=`__load Pashua default utility`
  if [ `echo $?` -ne 0 ]; then
    echo "Error: Couldn't load Pashua."
    kill -9 "$tmpPID"
    exit 1
  fi
fi

# Sixth, load/download Pashua.
if [ ! -f "$tn" ]; then
  tn=`__load terminal-notifier default utility`
  if [ `echo $?` -ne 0 ]; then
    echo "Error: Couldn't load Terminal Notifier."
    kill -9 "$tmpPID"
    exit 1
  fi
fi

# That's it. We're all good to go. The backgrounded check_setup.sh should
# call Alfred and Cron again within the next 10 seconds.
