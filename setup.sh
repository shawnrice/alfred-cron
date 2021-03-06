#!/bin/sh

# setup.sh checks to make sure all the necessary files are around; and, if not,
# sets everything up with appropriate error checking.

path="$( cd "$(dirname "$0")" ; pwd -P )"

. "$path/variables"

test_connection() {
  ping -c 1 -t 3 -q www.google.com > /dev/null 2>&1
  if [ 0 -eq $? ]; then
    echo "TRUE"
  else
    # Fallback in case ping is weird.
    tmp=`curl -sL http://www.google.com`
    if [ 0 -eq $? ]; then
      echo "TRUE"
    else
      echo "FALSE"
    fi
  fi
}

check() {
  # Basically, if the directories or anything is missing, then we'll install
  # the dependencies
  if [ ! -d "$1" ]; then
    # Something is wrong. Let's run through the setup.
    if [ -f "$data/assets/setup-complete" ]; then
      rm "$data/assets/setup-complete"
    fi
    nohup "$path/first-run.sh" > /dev/null 2>&1 &
    exit
  fi
}

check_bundler() {
  bundler="$HOME/Library/Application Support/Alfred 2/Workflow Data/alfred.bundler-aries"
  read -d '' please_wait <<-"_EOF_"
echo "<?xml version='1.0'?><items><item uid='' arg='' valid='no' autocomplete=''><title>Setting up cron...</title><subtitle>Downloading dependencies. Internet connection required.</subtitle><icon>icon.png</icon></item></items>"
_EOF_

  if [ -d "$bundler" ]; then

    if [ -f "$bundler/assets/bash/BashWorkflowHandler/default/workflowHandler.sh" ]; then
      if [ -e "$bundler/assets/utility/Pashua/default/Pashua.app" ]; then
        if [ ! -e "$bundler/assets/utility/Terminal-Notifier/default/terminal-notifier.app" ]; then
          sh -c "$please_wait"
          # Something is wrong. Let's run through the setup.
          if [ -f "$data/assets/setup-complete" ]; then
            rm "$data/assets/setup-complete"
          fi
            nohup "$path/first-run.sh" > /dev/null 2>&1 &
          exit
        fi
      else
        sh -c "$please_wait"

        # Something is wrong. Let's run through the setup.
        if [ -f "$data/assets/setup-complete" ]; then
          rm "$data/assets/setup-complete"
        fi
          nohup "$path/first-run.sh" > /dev/null 2>&1 &
        exit
      fi
    else
      sh -c "$please_wait"
      # Something is wrong. Let's run through the setup.
      if [ -f "$data/assets/setup-complete" ]; then
        rm "$data/assets/setup-complete"
      fi
      nohup "$path/first-run.sh" > /dev/null 2>&1 &
      exit 0
    fi
  else
    sh -c "$please_wait"
    # Something is wrong. Let's run through the setup.
    if [ -f "$data/assets/setup-complete" ]; then
      rm "$data/assets/setup-complete"
    fi
    nohup "$path/first-run.sh" > /dev/null 2>&1 &
    exit
  fi
}

# Check to see which icons to use.
if [ -e 'icon-dark.png' ]; then
  suffix='-light.png'
else
  suffix='.png'
fi

if [ ! -f "alfred.bundler.sh" ]; then
  if [ `test_connection` = 'FALSE' ]; then
    read -d '' error <<-"_EOF_"
echo "<?xml version='1.0'?><items><item uid='' arg='' valid='no' autocomplete=''><title>Error Setting up Alfred Cron</title><subtitle>An Internet connection is necessary to setup Alfred Cron. Please try again when you are connected.</subtitle><icon>icons/warning$suffix</icon></item></items>"
_EOF_
    sh -c "$error"
    exit 0
  fi
  curl -sL "https://raw.githubusercontent.com/shawnrice/alfred-bundler/aries/wrappers/alfred.bundler.sh" > alfred.bundler.sh
fi

# Check to see if the bundler is there.
check_bundler

# Bundler exists, so let's check for the directories.
check "$cache"
check "$data"
check "$logDir"
check "$scriptDir"
check "$enabledScriptDir"
check "$errorDir"
check "$data/assets"

###
# If we've gotten here, all the necessary files are downloaded.
###

. "$path/alfred.bundler.sh"

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