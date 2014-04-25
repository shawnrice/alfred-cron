#!/bin/sh

# People have wanted workflows to be called at a cetain time, so, here is a
# a daemon that is managed by an Alfred workflow that other people can hook into.
# I wrote a skeleton daemon file for people to use, which can be found at
# https://gist.github.com/shawnrice/11076762.
# This is an adapated version of that skeleton.

# Import the path variables
. variables

doCommands() {
  # This is where you put all the commands for the daemon.
  sh punchcard.sh
}

################################################################################
# Below is the skeleton functionality of the daemon.
################################################################################

myPid=`echo $$`

setupDaemon() {
  # Make sure that the directories work.
  if [ ! -d "$data" ]; then
    mkdir "$data"
  fi
  if [ ! -d "$cache" ]; then
    mkdir "$cache"
  fi
  if [ ! -d "$pidDir" ]; then
    mkdir "$pidDir"
  fi
  if [ ! -d "$logDir" ]; then
    mkdir "$logDir"
  fi
  if [ ! -d "$scriptDir" ]; then
    mkdir "$scriptDir"
  fi
  if [ ! -d "$enabledScriptDir" ]; then
    mkdir "$enabledScriptDir"
  fi
  if [ ! -f "$logFile" ]; then
    touch "$logFile"
  else
    # Check to see if we need to rotate the logs.
    size=$((`stat -f%z "$logFile"`/1024))
    if [[ $size -gt $logMaxSize ]]; then
      mv $logFile "$logFile.old"
      touch "$logFile"
    fi
  fi
}

startDaemon() {
  # Start the daemon.
  setupDaemon # Make sure the directories are there.
  if [[ `checkDaemon` = 1 ]]; then
    echo " * \033[31;5;148mError\033[39m: $daemonName is already running."
    exit 1
  fi
  echo " * Starting $daemonName with PID: $myPid."
  echo "$myPid" > "$pidFile"
  log '*** '`date +"%Y-%m-%d %H:%M:%S"`": Starting up $daemonName."

  # Start the loop.
  loop
}

stopDaemon() {
  # Stop the daemon.
  if [[ `checkDaemon` -eq 0 ]]; then
    echo " * \033[31;5;148mError\033[39m: $daemonName is not running."
    exit 1
  fi
  echo " * Stopping $daemonName"
  log '*** '`date +"%Y-%m-%d  %H:%M:%S"`": $daemonName stopped."

  if [[ ! -z `cat "$pidFile"` ]]; then
    kill -9 `cat "$pidFile"` &> /dev/null
    rm "$pidFile"
  fi
}

statusDaemon() {
  # Query and return whether the daemon is running.
  if [[ `checkDaemon` -eq 1 ]]; then
    echo " * $daemonName is running."
  else
    echo " * $daemonName isn't running."
  fi
  exit 0
}

restartDaemon() {
  # Restart the daemon.
  if [[ ! `checkDaemon` -eq 1 ]]; then
    # Can't restart it if it isn't running.
    echo "$daemonName isn't running."
    exit 1
  fi
  stopDaemon
  startDaemon
}

checkDaemon() {
  # Check to see if the daemon is running.
  # This is a different function than statusDaemon
  # so that we can use it other functions.
  if [ -z "$oldPid" ]; then
    echo 0
    return 0
  elif [[ `ps aux | grep "$oldPid" | grep "$daemonName" | grep -v grep` > /dev/null ]]; then
    if [ -f "$pidFile" ]; then
      if [[ `cat "$pidFile"` = "$oldPid" ]]; then
        # Daemon is running.
        echo 1
        return 1
      else
        # Daemon isn't running.
        echo 0
        return 0
      fi
    fi
  elif [[ `ps aux | grep "$daemonName" | grep -v grep | grep -v "$myPid" | grep -v "0:00.00"` > /dev/null ]]; then
    # Daemon is running but without the correct PID. Restart it.
    log '*** '`date +"%Y-%m-%d"`": $daemonName running with invalid PID; restarting."
    restartDaemon
    echo 1
    return 1
  else
    # Daemon not running.
    echo 0
    return 0
  fi
  echo 1
  return 1
}

check() {
  if [[ `checkDaemon` -eq 1 ]]; then
    echo "TRUE"
  else
    echo "FALSE"
  fi
  exit 0
}

loop() {
  # This is the loop.
  now=`date +%s`

  if [ -z $last ]; then
    last=`date +%s`
  fi

  # Do everything you need the daemon to do.
  doCommands

  # Check to see how long we actually need to sleep for. If we want this to run
  # once a minute and it's taken more than a minute, then we should just run it
  # anyway.
  last=`date +%s`

  # Set the sleep interval
  if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
    sleep $((now-last+runInterval))
  fi

  # Startover
  loop
}

log() {
  # Generic log function.
  echo "$1" > "$cache/tmpRunFile"
  cat "$logFile" > "$cache/tmpRunFile"
  mv "$cache/tmpRunFile" "$logFile"
}


################################################################################
# Parse the command.
################################################################################

if [ -f "$pidFile" ]; then
  oldPid=`cat "$pidFile"`
fi

case "$1" in
  start)
  startDaemon
  ;;
  stop)
  stopDaemon
  ;;
  status)
  statusDaemon
  ;;
  restart)
  restartDaemon
  ;;
  check)
  check
  ;;
  *)
  echo "\033[31;5;148mError\033[39m: usage $0 { start | stop | restart | status }"
  exit 1
esac

exit 0