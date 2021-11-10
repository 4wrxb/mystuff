#!/usr/bin/env bash

##############################
# Sanity checks
##############################
sanity_checks_ok=0
if ! . Sanity_checks.sh || [ $sanity_checks_ok -ne "1" ]; then
  echo "The sanity check script failed or could not be found, exiting."
  exit
fi

##############################
# Copy .ssh
##############################
cd "$(dirname "$0")"
# Move the old .ssh out of the way. TODO: don't need to do this if the only thing there is the work key (or empty)
if [ -d $HOME/.ssh ]; then
  echo "Moving existing .ssh to .ssh.old"
  m\v $HOME/.ssh $HOME/.ssh.old
  # work key gits put first in the boot-strap process. Move that back.
  if [ -f $HOME/.ssh.old/$USER.openSSH ]; then
    m\v $HOME/.ssh.old/$USER.openSSH $HOME/.ssh/
  fi
fi
cppath=$(which cp)
if [ $(readlink -f $cppath | grep "busybox") ]; then
  echo "busybox detected, doing simple cp, check ownership/perms of copied files"
  c\p -iR .ssh $HOME/
else
  c\p -viR --no-preserve=ownership .ssh $HOME/
fi

##############################
# Copy .gitconfig but don't overwrite
# STOPPING .gitconfig use, moving to .config
##############################
#cd "$(dirname "$0")"
#cppath=`which cp`
#if [ `readlink -f $cppath | grep "busybox"` ]
#then
#  echo "busybox detected, doing simple cp, check ownership/perms of copied files"
#  c\p -i .gitconfig $HOME/.gitconfig.new
#else
#  c\p -vi --no-preserve=ownership .gitconfig $HOME/.gitconfig.new
#fi
#
#if [ -f $HOME/.gitconfig ]
#then
#  echo ".gitconfig exists, leave .gitconfig.new for manual merge"
#else
#  m\v $HOME/.gitconfig.new $HOME/.gitconfig
#fi

##############################
# WSL-specific changes
##############################
uname_result=$(uname -r)
if [ "${uname_result%Microsoft}" != "$uname_result" ]; then
  echo "Making WSL speicfic changes"
  ./Install_wsl_software.sh
fi

##############################
# Now run the injector for includes
##############################
./Include_injector.sh
