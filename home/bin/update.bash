#!/usr/bin/env bash

if ! command -v 'sudo' > /dev/null 2>&1; then
  echo "nosudo"
  # just guess that we're already root if sudo doesn't exist
  alias sudo=''
fi

# Package Manger Updates
if command -v 'apt' > /dev/null 2>&1; then
  echo "apt"
  sudo apt update
  sudo apt upgrade
  sudo apt autoremove
elif command -v 'aptitude' > /dev/null 2>&1; then
  echo "aptitude"
  sudo aptitude update
  sudo aptitude safe-upgrade
elif command -v 'apt-get' > /dev/null 2>&1; then
  echo "apt-get"
  sudo apt-get update
  sudo apt-get upgrade
  sudo apt-get autoremove
elif command -v 'yum' > /dev/null 2>&1; then
  echo "yum"
  sudo yum upgrade
else
  echo "package manager not found"
fi

# golang updates on debian - godeb downloads packages to cwd, doesn't appear to support overrides
cd /tmp
if command -v 'dpkg' > /dev/null 2>&1; then
  echo "on a deb-based system, checking for go"
  if command -v 'go' > /dev/null 2>&1; then
    echo "go exists, checking for godeb"
    if command -v 'godeb' > /dev/null 2>&1; then
      echo "godeb is installed, running it directly"
      echo "  note: if godeb needs updated run go get -u gopkg.in/niemeyer/godeb.v1/cmd/godeb"
      echo "  HOWEVER: you must have access to the current godeb location in your go path"
      godeb install
    elif [ ! -z ${GOPATH+x} ] || [ -d $HOME/go ]; then
      echo "go appears to be in use, but godeb is not found, installing"
      go get -u gopkg.in/niemeyer/godeb.v1/cmd/godeb
      godeb install
    fi
    echo "cleaning up godeb packages"
    rm /tmp/go_*.deb > /dev/null 2>&1
  fi
fi
