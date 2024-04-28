#!/bin/sh
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $

# Installs software I use on WSL
# Assumes env (including any proxies) already set up
# Does NOT use Sanity_checks.sh since this isn't dependent on most of that

# TODO: compare vs personal WSL setup

uname_result=$(uname -r)
if [ "${uname_result%icrosoft*}" = "$uname_result" ]; then
  echo "ERROR: this script is intended for WSL only."
  exit 1
fi

# apt install
# GENERAL:
# - git-crypt (probably already done by bootstrap, but harmless to repeat)
# - git-gui (bring gitk and a lot of font/X11 stuff I'll need anyway
# - go
# - kdiff3
# - meld
# - perlbrew (gives us some build env too)
# - python3
# - unzip
# - wget
# - zsh
# FOR OPENWRT:
# - build-essential
# - libncurses5-dev
# - libncursesw5-dev
# - python2
# - zlib1g-dev
# - gawk
# - gettext
# - libssl-dev
# - xsltproc
# FIXME: prompt for openwrt? Won't need it on work machines
echo "Running apt install through sudo. Enter password if prompted."
sudo apt update
sudo apt install git-crypt git-gui go kdiff3 meld perlbrew python3 unzip wget zsh build-essential libncurses5-dev libncursesw5-dev python2 zlib1g-dev gawk gettext libssl-dev xsltproc

# If gopath is already being set leave it alone
if [ -z "$GOPATH" ]; then
  echo '' >> "$HOME"/.profile
  printf '\nexport GOPATH="$HOME/go"\n' >> "$HOME"/.profile
  # Set gopath manually so we don't need to re-source anything
  export GOPATH="$HOME/go"
fi

if [ ! -d "$HOME"/go ]; then
  mkdir "$HOME"/go
fi

# set up assh through go
if ! command -v 'assh' > /dev/null 2>&1; then
  if ! command -v 'go' > /dev/null 2>&1; then
    echo "assh not found, but nor is go. Did go install successfully? Re-run this script after restarting your shell."
  else
    echo "assh not found, installing."
    GO111MODULE=on go get -u moul.io/assh/v2
    if command -v 'assh' > /dev/null 2>&1; then
      echo "assh successfully installed, building first config and setting the alias (will happen automatically in the future)."
      if [ -f "$HOME"/.ssh/config ]; then
        mv "$HOME"/.ssh/config "$HOME"/.ssh/config_pre_assh
      fi
      assh config build > "$HOME"/.ssh/config
      chmod 600 "$HOME"/.ssh/config
      alias ssh='assh wrapper ssh'

      # Work-around for wonkiness in assh
      mkdir -p "$HOME"/tmp/.ssh/cm

      #TODO: prompt before setting up assh devel environment?
      #TODO: generalize the godevel process and call that?
      cd "$HOME"/go/src/moul.io/assh || exit
      git remote add my-fork git@github.com:4wrxb/assh.git
      git fetch my-fork
      git branch master -u my-fork/master
      git branch upstream_master origin/master
      git fetch my-fork master && git reset --hard FETCH_HEAD
      go install moul.io/assh
    else
      echo "assh failed to install, did NOT set up config file etc.. Please check on your (a)ssh install."
    fi
  fi
fi
