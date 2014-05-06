#!/bin/sh

# This is a simple script that should be called when Alfred Cron isn't setup.
# It will hang out in the background, and, after everything is setup, then it
# will trigger Alfred's Cron again.

path="$( cd "$(dirname "$0")" ; pwd -P )"
. "$path/variables"

while [ ! -f "$data/assets/setup-complete" ];
do
  sleep 5
done

rm "$data/assets/setup-complete"
. "$path/alfred.bundler.sh"

script="tell application \"Alfred 2\" to run trigger \"com.alfred.cron\" in workflow \"alfred.cron.spr\""
tn="$HOME/Library/Application Support/Alfred 2/Workflow Data/alfred.bundler-aries/assets/utility/terminal-notifier/default/terminal-notifier.app/Contents/MacOS/terminal-notifier"

"$tn" -title 'Setup Complete' \
 -message "Alfred Cron is now ready to use." \
 -execute "osascript -e '$script'" \
 -group 'alfredcron'

 sleep 3

 osascript -e "$script"
