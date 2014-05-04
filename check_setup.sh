#!/bin/sh

# This is a simple script that should be called when Alfred Cron isn't setup.
# It will hang out in the background, and, after everything is setup, then it
# will trigger Alfred's Cron again.

. variables

while [ ! -f "$data/assets/setup-complete" ];
do
  sleep 10
done

rm "$data/assets/setup-complete"

script="tell application \"Alfred 2\" to run trigger \"com.alfred.cron\" in workflow \"alfred.cron.spr\""
osascript -e "$script"
