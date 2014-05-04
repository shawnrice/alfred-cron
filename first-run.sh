#!/bin/sh

test_connection() {
  ping -c 1 -t 2 -q www.google.com > /dev/null 2>&1

  if [ 0 -eq $? ]; then
    echo 1
  else
    echo 0
  fi
}

check_bundler() {
  bundler="$HOME/Library/Application Support/Alfred 2/Workflow Data/alfred.bundler-aries"
  if [ -d "$bundler" ]; then
    if [ -f "$bundler/assets/bash/BashWorkflowHandler/default/workflowHandler.sh" ]; then
      if [ -e "$bundler/assets/utility/Pashua/default/Pashua.app" ]; then
        if [ ! -e "$bundler/assets/utility/Terminal-Notifier/default/terminal-notifier.app" ]; then
          sh -c "$please_wait"
          exit 0
        fi
      else
        sh -c "$please_wait"
        exit 0
      fi
    else
      sh -c "$please_wait"
      exit 0
    fi
  else
    sh -c "$please_wait"
    exit 0
  fi
}

dir() {
  if [ ! -d "$1" ]; then
    mkdir "$1"
  fi
}

. variables


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


if [ ! `test_connection` -eq 1 ]; then
  please_wait='echo "<?xml version='1.0'?><items><item uid='' arg='' valid='no' autocomplete=''><title>Error Setting up Alfred Cron</title><subtitle>An Internet connection is necessary to setup Alfred Cron. Please try again when you are connected.</subtitle><icon>icon.png</icon></item></items>"'
  sh -c "$please_wait"
  exit 1
fi

./check-setup.sh &> /dev/null
tmpPID=`echo $$`

bundler="$HOME/Library/Application Support/Alfred 2/Workflow Data/alfred.bundler-aries"
please_wait='echo "<?xml version='1.0'?><items><item uid='' arg='' valid='no' autocomplete=''><title>Setting up cron...</title><subtitle>Downloading dependencies. Internet connection required.</subtitle><icon>icon.png</icon></item></items>"'
sh -c "$please_wait"
exit
if [ -d "$bundler" ]; then
  if [ -f "$bundler/assets/bash/BashWorkflowHandler/default/workflowHandler.sh" ]; then
    if [ -e "$bundler/assets/utility/Pashua/default/Pashua.app" ]; then
      if [ ! -e "$bundler/assets/utility/Terminal-Notifier/default/terminal-notifier.app" ]; then
        sh -c "$please_wait"
        exit 0
      fi
    else
      sh -c "$please_wait"
      exit 0
    fi
  else
    sh -c "$please_wait"
    exit 0
  fi
else
  sh -c "$please_wait"
  exit 0
fi


# script : "tell application \"Alfred 2\" to run trigger \"com.alfred.cron\" in workflow \"alfred.cron.spr\" with argument \"test\""
# ping -q ya.ru 2>&1 1>/dev/null | grep -v 'ping: sendto: No route to host' >&2

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
