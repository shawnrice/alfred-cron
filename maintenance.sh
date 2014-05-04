#!/bin/bash

# This script cleans the punchcard and the registry files to make sure that they
# contain only extant jobs.

path="$( cd "$(dirname "$0")" ; pwd -P )"
. "$path/variables"

if [ ! -d "$cache" ]; then
  mkdir "$cache"
fi

if [ -f "$cache/registry_maintenance.tmp" ]; then
  rm "$cache/registry_maintenance.tmp"
fi
touch "$cache/registry_maintenance.tmp"
for j in "$scriptDir/"*
do
  j=$(basename "$j")
  echo `cat "$data/registry"  | grep "$j="` >> "$cache/registry_maintenance.tmp"
done
mv "$cache/registry_maintenance.tmp" "$data/registry"

if [ -f "$cache/punchcard_maintenance.tmp" ]; then
  rm "$cache/punchcard_maintenance.tmp"
fi
touch "$cache/punchcard_maintenance.tmp"
for j in "$scriptDir/"*
do
  j=$(basename "$j")
  echo `cat "$data/punchcard"  | grep "$j=" ` >> "$cache/punchcard_maintenance.tmp"
done
mv "$cache/punchcard_maintenance.tmp" "$data/punchcard"
