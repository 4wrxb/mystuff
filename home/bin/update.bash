#!/usr/bin/env bash

if ! type 'sudo' > /dev/null 2>&1
then
  echo "nosudo"
  # just guess that we're already root if sudo doesn't exist
  alias sudo=''
fi

if type 'apt' > /dev/null 2>&1
then
  echo "apt"
  sudo apt update; sudo apt upgrade; sudo apt autoremove
elif type 'aptitude' > /dev/null 2>&1
then
  echo "aptitude"
  sudo aptitude update; sudo aptitude safe-upgrade
elif type 'apt-get' > /dev/null 2>&1
then
  echo "apt-get"
  sudo apt-get update; sudo apt-get upgrade; sudo apt-get autoremove
elif type 'yum' > /dev/null 2>&1
then
  echo "yum"
  sudo yum upgrade
else
  echo "package manager not found"
fi

