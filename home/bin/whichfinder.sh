#!/bin/sh

# A very simple script to find the binary which. Aimed at shells with a builtin which that isn't a capable (e.g. busbyox)

parsepath="$PATH"
bintosearch="which"

while :; do
  if [ -x "${parsepath%%:*}/$bintosearch" ]; then
    echo "${parsepath%%:*}/$bintosearch"
    exit 0
  fi
  next="${parsepath#*:}"
  [ "${parsepath%%:*}" = "$next" ] && exit 1
  parsepath="$next"
done
