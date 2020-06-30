#!/bin/false

myexit() {
exit $1
echo "got code $1"
echo "externalinstdir: $externalinstdir"
echo "homedir: $homedir"
echo "realhome: $realhome"
echo "instdir: $instdir"
echo "realinstdir: $realinstdir"
}

##############################
# Get our bearings (path munching)
##############################
if [ ! -z $INST_HOME ]; then
  homedir=$INST_HOME
elif [ ! -z $HOME ]; then
  homedir=$HOME
else
  echo "ERROR, \$HOME is not set"
  myexit 1
fi

if [ -z $instdir ]; then
  instdir="$( cd "$( dirname "${0}" )" && pwd )"
fi

realhome=`readlink -f $homedir`
realinstdir=`readlink -f $instdir`

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
if [ ! "${realinstdir##$realhome}" != "${realinstdir}" ]; then
  echo "WARNING: Installdir ($instdir) is not inside home. This is not recommended,"
  echo "         but OK if you know the dir is permanent and portable. Continue?"
  echo "CAREFUL: if instdir IS in home please answer no and reurn with overrides to fix this"
  echo "         INST_HOME overrides \$HOME, instdir overrides install dir"
  old_stty_cfg=$(stty -g)
  stty raw -echo
  answer=$( while ! head -c 1 | grep -i '[ny]'; do true; done )
  stty $old_stty_cfg
  if echo "$answer" | grep -q "^y"; then
    externalinstdir=1
  else
    myexit 1
  fi
fi

# Check if home lives on a remote filesystem, if so confirm it's portable
if [ "$(stat -f -L -c %T $homedir)" = "*nfs*" ]; then
  if [ "$homedir" = "$realhome" ]; then # Assume it's portable if it's linked
    echo "WARNING: Home path $homedir is remote, but directly referenced."
    echo "         Is this a portable path?"
    old_stty_cfg=$(stty -g)
    stty raw -echo
    answer=$( while ! head -c 1 | grep -i '[ny]'; do true; done )
    stty $old_stty_cfg
    if echo "$answer" | grep -q "^n"; then
      echo "re-run with \"INST_HOME=/portable/home/path\" in front"
      myexit 1
    fi
  else
    echo "INFO: assuming nfs home path $homedir is portable since it is linked to $realhome"
  fi
fi

sanity_checks_ok=1
