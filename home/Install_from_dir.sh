#!/bin/sh

##############################
# Sanity checks
##############################
sanity_checks_ok=0
if ! . ./Sanity_checks.sh || [ $sanity_checks_ok -ne "1" ]; then
  echo "The sanity check script failed or could not be found, exiting."
  exit
fi

##############################
# Copy .ssh
##############################
cd "$(dirname "$0")" || exit 1
# Move the old .ssh out of the way. TODO: don't need to do this if the only thing there is the work key (or empty)
if [ -d "$HOME"/.ssh ]; then
  echo "Moving existing .ssh to .ssh.old"
  \mv "$HOME"/.ssh "$HOME"/.ssh.old
  # work key gets put first in the boot-strap process. Move that back.
  if [ -f "$HOME"/.ssh.old/"$USER".openSSH ]; then
    \mv "$HOME"/.ssh.old/"$USER".openSSH "$HOME"/.ssh/
  fi
fi
cppath=$(which cp)
# TODO: better test
if readlink -f "$cppath" | grep -q "busybox"; then
  echo "busybox detected, doing simple cp, check ownership/perms of copied files"
  \cp -iR .ssh "$HOME"/
else
  \cp -viR --no-preserve=ownership .ssh "$HOME"/
fi

##############################
# Copy .gitconfig but don't overwrite
##############################
# TODO: better test
if readlink -f "$cppath" | grep -q "busybox"; then
  echo "busybox detected, doing simple cp, check ownership/perms of copied files"
  \cp -i .gitconfig "$HOME"/.gitconfig.new
else
  \cp -vi --no-preserve=ownership .gitconfig "$HOME"/.gitconfig.new
fi

if [ -f "$HOME"/.gitconfig ]; then
  echo ".gitconfig exists, leave .gitconfig.new for manual merge"
else
  \mv "$HOME"/.gitconfig.new "$HOME"/.gitconfig
fi

##############################
# Conifg Links
##############################
# vim
if [ -f "$HOME"/.vimrc ]; then
  echo ".vimrc exists - NOT updating"
else
  \ln -s .vimrc "$HOME"/.vimrc
fi

# tmux
if [ -f "$HOME"/.tmux.conf ]; then
  echo ".tmux.conf exists, moving to to .tmux.conf.orig, suggest merging into .tmux.conf.local"
  \mv "$HOME"/.tmux.conf "$HOME"/.tmux.conf.orig
fi

if [ -f "$HOME"/.tmux.conf.local ]; then
  echo ".tmux.conf.local exists, moving to .tmux.conf.local.orig, suggest mergining into .tmux.conf.local"
fi

\ln -s .tmux.conf "$HOME"/.tmux.conf
\ln -s .tmux.conf.user "$HOME"/.tmux.user
# TODO: smarter way of doing this?
echo 'ACTION REQUIRED: link the appropriate mystuff/home/.tmux.conf.local.* to .tmux.conf.local'
echo '                 or make a new copy for mystuff/home/.tmux.conf.local.template'

##############################
# WSL-specific changes
##############################
uname_result=$(uname -r)
if [ "${uname_result%icrosoft*}" != "$uname_result" ]; then
  echo "Making WSL speicfic changes"
  . ./Install_wsl_software.sh
fi

##############################
# Now run the injector for includes
##############################
./Include_injector.sh
