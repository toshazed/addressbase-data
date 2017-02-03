#!/bin/bash

# download a zip file using the URL found in a local copy of the OS "Order download" page
# - depends upon the session information contained in the file

out="$1"
file=$(basename "$out")

grep '<li>' |
  grep $file |
  sed -e "s/^.*<a href=[\"|']//" -e "s/[\"|']>Add.*$//" -e 's/&amp;/\&/g' |
      xargs curl -s  > "$out"
