#!/bin/sh

. variables

if [ "$1" = "setup" ]; then
  echo "Hello!"
fi

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

if [ ! -f "alfred.bundler.sh" ]; then
  curl -sL "https://raw.githubusercontent.com/shawnrice/alfred-bundler/aries/wrappers/alfred.bundler.sh" > alfred.bundler.sh
fi

. alfred.bundler.sh

BashWorkflowHandler=`__load BashWorkflowHandler`
Pashua=`__load Pashua default utility`