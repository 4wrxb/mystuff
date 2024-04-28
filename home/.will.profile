#!/bin/false
# shellcheck shell=sh
# ~/.will.profile: Cross-platform options for login shells...

secho() {
  case $- in
    *i*) echo "$@" ;;
    *) return 1 ;;
  esac
}

secho "running .will.profile"

uname_result=$(uname -r)
if [ "${uname_result%icrosoft*}" != "$uname_result" ]; then
  # winhome link
  tmp_winuser=$USER
  tmp_newln=1
  if [ -h "${HOME}/winhome" ]; then   #Existing link
    if [ -d "${HOME}/winhome" ]; then #Link is to valid dir
      tmp_newln=0
    else
      rm "${HOME}/winhome" > /dev/null 2>&1
    fi
  fi
  if [ $tmp_newln -eq 1 ] && ! [ -d "/mnt/c/Users/${tmp_winuser}" ]; then
    # shellcheck disable=SC2018,2019 # classes not universally supported
    tr 'A-Z' 'a-z' < "$tmp_winuser"
    if ! [ -d "/mnt/c/Users/${tmp_winuser}" ]; then
      # FIXME: this contains bashisms
      #      tmp_winuser="$(tr '[a-z]' '[A-Z]' <<< ${tmp_winuser:0:1})${tmp_winuser:1}"
      tmp_winuser=will
      if ! [ -d "/mnt/c/Users/${tmp_winuser}" ]; then
        tmp_newln=0
      fi
    fi
  fi
  if [ $tmp_newln -eq 1 ]; then
    ln -s "/mnt/c/Users/${tmp_winuser}" "${HOME}/winhome"
  fi
fi

# FIXME: move this to env in the injected includes
# shellcheck disable=all
mystuffpath="$(readlink -f $(dirname $BASH_SOURCE[0]))"
secho "mystuff is here: $mystuffpath"

##############################
# SSH-AGENT
##############################
# From git-for-windows documentation this seems to be more universal than other linux suggestions
case $- in
  *i*) . "$mystuffpath"/launch_ssh_agent.sh ;;
  *) ;;
esac

##############################
# PATH
##############################
# Add the go path first
if [ -d "$HOME/go/bin" ]; then
  PATH="$HOME/go/bin":$PATH
fi

# Add the mystuff bin to $PATH
if [ -d "${mystuffpath}/bin" ]; then
  PATH="${mystuffpath}/bin":$PATH
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin":$PATH
fi

##############################
# OTHER ENV
##############################
# Source aliases last (so they have the full path etc.)
if [ -f "${mystuffpath}/will.aliases" ]; then
  . "${mystuffpath}/will.aliases"
fi

if [ -f "$HOME/workstuff/wsl/work_env" ]; then
  . "$HOME/workstuff/wsl/work_env"
fi
