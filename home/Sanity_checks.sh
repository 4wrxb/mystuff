#!/bin/false
# shellcheck shell=sh
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $
myexit() {
  # echo "got code $1"
  # echo "externalinstdir: $externalinstdir"
  # echo "homedir: $homedir"
  # echo "realhome: $realhome"
  # echo "instdir: $instdir"
  # echo "realinstdir: $realinstdir"
  exit "$1"
}

get_yn() {
  echo "Type y/n for yes/no:"
  old_stty_cfg=$(stty -g)
  stty raw -echo
  answer=$(while ! head -c 1 | grep -i '[ny]'; do true; done)
  stty "$old_stty_cfg"
  if echo "$answer" | grep -q "^y"; then
    return 0 # yes
  else
    return 1 # no
  fi
}

##############################
# Get our bearings (path munching)
##############################
if [ -n "$INST_HOME" ]; then
  homedir="$INST_HOME"
elif [ -n "$HOME" ]; then
  homedir="$HOME"
else
  echo 'ERROR, $HOME is not set'
  myexit 1
fi

# OPEN: I forget why I did this - readlink is already below
if [ -z "$instdir" ]; then
  instdir="$(cd "$(dirname "${0}")" && pwd)"
fi

realhome=$(readlink -f "$homedir")
realinstdir=$(readlink -f "$instdir")

##############################
# Sanity checks
##############################
externalinstdir=0
# be extra paranoid in case the downloader used tmp dir
# the not equals means the replacement *worked* so realinstdir IS in tmp
if [ "${realinstdir##/tmp}" != "${realinstdir}" ]; then
  echo "ERROR: instdir is in tmp, please place in a permament location"
  myexit 1
fi

# Use replacement to test if de-referenced install dir is inside derefenced home
# the not equals means the replacement *worked* so realinstdir IS in realhome
if [ ! "${realinstdir##"$realhome"}" != "${realinstdir}" ]; then
  echo "WARNING: Installdir ($instdir) is not inside home. This is not recommended,"
  echo "         but OK if you know the dir is permanent and portable. Continue?"
  echo "CAREFUL: if instdir IS in home please answer no and reurn with overrides to fix this"
  echo '         INST_HOME overrides $HOME, instdir overrides install dir'
  if get_yn; then
    # shellcheck disable=SC2034 # used by sourcing script
    externalinstdir=1
  else
    myexit 1
  fi
fi

# Check if home lives on a remote filesystem, if so confirm it's portable
if [ "$(stat -f -L -c %T "$homedir")" = "*nfs*" ]; then
  if [ "$homedir" = "$realhome" ]; then # Assume it's portable if it's linked
    echo "WARNING: Home path $homedir is remote, but directly referenced."
    echo "         Is this a portable path?"
    old_stty_cfg=$(stty -g)
    stty raw -echo
    answer=$(while ! head -c 1 | grep -i '[ny]'; do true; done)
    stty "$old_stty_cfg"
    if echo "$answer" | grep -q "^n"; then
      echo 're-run with "INST_HOME=/portable/home/path" in front'
      myexit 1
    fi
  else
    echo "INFO: assuming nfs home path $homedir is portable since it is linked to $realhome"
  fi
fi

# shellcheck disable=SC2034 # used by sourcing script
sanity_checks_ok=1

##############################
# safe_cp
##############################
# Make sure we have the best working cp command for these scripts
testa=/tmp/testa.$$
testb=/tmp/testb.$$
alias _test_prep 'rm -f "$testb"; touch "$testa"; :'
if (_test_prep && \cp -viR --no-preserve=ownership "$testa" "$testb") > /dev/null; then
  # Best case verbose & interactive using --no-preserve=ownership to force creation of the file as running user
  safe_cp() {
    \cp -viR --no-preserve=ownership "$@"
  }
else
  # Otherwise we will try to chown - but check other flags:
  if (_test_prep && \cp -viR "$testa" "$testb"); then
    _safe_cp_flags="-viR"
  elif \cp -iR; then
    _safe_cp_flags="-iR"
  else
    _safe_cp_flags="-R"
  fi

  if (_test_prep && \chown -R "$USER" "$testa"); then
    # Chown is possible - get the last argument to cp and make sure $USER owns it
    safe_cp() {
      \cp "$_safe_cp_flags" "$@"
      for last; do :; done
      \chown -R "$USER" "$last"
    }
  else
    # Fall-back - just copy
    safe_cp() {
      \cp "$_safe_cp_flags" "$@"
    }
  fi
fi

# TODO: testing differnt forms of safe_cp
# TODO: return status of safe cp?

unset testa testb
unalias _test_prep
