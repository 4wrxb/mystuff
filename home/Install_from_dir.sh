#!/bin/sh
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $

##############################
# Sanity checks
##############################
sanity_checks_ok=0
if ! . "$(readlink -e "$(dirname "$0")")"/Sanity_checks.sh || [ $sanity_checks_ok -ne "1" ]; then
  echo "The sanity check script failed or could not be found, exiting."
  exit
fi

if [ -z "$homedir" ] || [ -z "$instdir" ] || [ -z "$realhome" ] || [ -z "$realinstdir" ] || [ -z "$externalinstdir" ]; then
  echo "ERROR: the Sanity_checks failed to provide necessary information"
  exit
fi

##############################
# Copy .ssh
##############################
# TODO: add a proper guard
# Move the old .ssh out of the way. TODO: don't need to do this if the only thing there is the work key (or empty)
if false; then
  if [ -d "$HOME"/.ssh ]; then
    echo "Moving existing .ssh to .ssh.old"
    \mv "$HOME"/.ssh "$HOME"/.ssh.old
    # work key gets put first in the boot-strap process. Move that back.
    if [ -f "$HOME"/.ssh.old/"$USER".openSSH ]; then
      \mv "$HOME"/.ssh.old/"$USER".openSSH "$HOME"/.ssh/
    fi
  fi

  safe_cp "$realinstdir"/.ssh "$HOME"/
fi

##############################
# Copy .gitconfig but don't overwrite
##############################
# TODO: better test
safe_cp "$realinstdir"/.gitconfig "$HOME"/.gitconfig.new

if [ -f "$HOME"/.gitconfig ]; then
  echo ".gitconfig exists, leave .gitconfig.new for manual merge"
else
  \mv "$HOME"/.gitconfig.new "$HOME"/.gitconfig
fi

(cd "$HOME" && \ln -sr "$realinstdir"/.gitconfig.common "$HOME"/.gitconfig.common) || echo 'Unable to link .gitconfig.common to $HOME/.gitconfig.common, please do manually.'

##############################
# Conifg Links
##############################
# vim
if [ -f "$HOME"/.vimrc ]; then
  echo ".vimrc exists - NOT updating"
else
  (cd "$HOME" && \ln -sr "$realinstdir"/.vimrc "$HOME"/.vimrc) || echo 'Unable to link .vimrc to $HOME/.vimrc, please do manually.'
fi

# tmux
if [ -f "$HOME"/.tmux.conf ]; then
  echo ".tmux.conf exists, moving to to .tmux.conf.orig, suggest merging into .tmux.conf.local"
  \mv "$HOME"/.tmux.conf "$HOME"/.tmux.conf.orig
fi

if [ -f "$HOME"/.tmux.conf.local ]; then
  echo ".tmux.conf.local exists, moving to .tmux.conf.local.orig, suggest mergining into .tmux.conf.local"
fi

(cd "$HOME" && \ln -sr "$realinstdir"/.tmux.conf "$HOME"/.tmux.conf) || echo 'Unable to link .tmux.conf to $HOME/.tmux.conf, please do manually.'
(cd "$HOME" && \ln -sr "$realinstdir"/.tmux.conf.user "$HOME"/.tmux.user) || echo 'Unable to link .tmux.conf.user to $HOME/.tmux.conf.user, please do manually.'
# TODO: smarter way of doing this?
echo 'ACTION REQUIRED: link the appropriate .tmux.conf.local.* to $HOME/.tmux.conf.local'
echo '                 or make a new copy from .tmux.conf.local.template'

##############################
# WSL-specific changes
##############################
uname_result=$(uname -r)
if [ "${uname_result%icrosoft*}" != "$uname_result" ]; then
  echo "Making WSL speicfic changes"
  . "$realinstdir"/Install_wsl_software.sh
fi

##############################
# Now run the injector for includes
##############################
"$realinstdir"/Include_injector.sh
