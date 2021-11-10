#!/bin/sh

statA=$(stat -c "%A" .)
statG=$(stat -c "%G" .)

case $statA in
  drwxr??r??) readprefix="a" ;;
  drwxr??-??) readprefix="g" ;;
  drwx-??r??) readprefix="o" ;;
  drwx-??-??) readprefix="u" ;;
  *)
    echo "ERROR: current directory's read permissions are not understood. Template \"$statA\" is unreliable."
    exit
    ;;
esac

case $statA in
  drwx?w??w?) writeprefix="a" ;;
  drwx?w??-?) writeprefix="g" ;;
  drwx?-??w?) writeprefix="o" ;;
  drwx?-??-?) writeprefix="u" ;;
  *)
    echo "ERROR: current directory's read permissions are not understood. Template \"$statA\" is unreliable."
    exit
    ;;
esac

if [ "$readprefix" = "o" ]; then
  while :; do
    echo "The current directory is currently group UNreadable but other readable."
    echo "Would you like to fix this and make both group and other readable? [Y]es/[N]o: "
    read $yn
    case $yn in
      Yes | yes | y | Y)
        readprefix="a"
        break
        ;;
      No | no | n | N) break ;;
    esac
  done
fi

if [ "$writeprefix" = "o" ]; then
  while :; do
    echo "The current directory is currently group UNwriteable but other writeable."
    echo "Would you like to fix this and make both group and other readable? [Y]es/[N]o: "
    read $yn
    case $yn in
      Yes | yes | y | Y)
        writeprefix="a"
        break
        ;;
      No | no | n | N) break ;;
    esac
  done
fi

export octnxec
export octexec
export octdirs

echo "The current directory $(readlink -f .) tree will be set to the following permissions:"
echo "  Group: $statG"
case $readprefix in
  a)
    echo "  Read:  ALL"
    octnxec=444
    ;;
  g)
    echo "  Read:  User & Group"
    octnxec=440
    ;;
  o)
    echo "  Read:  User & Other"
    octnxec=404
    ;;
  u)
    echo "  Read:  User Only"
    octnxec=400
    ;;
esac

octexec=$((octnxec / 4 + octnxec))

case $writeprefix in
  a)
    echo "  Write: ALL"
    octwr=222
    ;;
  g)
    echo "  Write: User & Group"
    octwr=220
    ;;
  o)
    echo "  Write: User & Other"
    octwr=202
    ;;
  u)
    echo "  Write: User Only"
    octwr=200
    ;;
esac

octnxec=$((octnxec + octwr))
octexec=$((octexec + octwr))
octdirs=$((octexec + 2000))

echo "  Execute will be SET for directories and executable files."
echo "          It will be UNTOUCHED for others (but reported if set)."
echo "  Links will NOT be travesed."
echo "(DEBUG)Bitmasks:"
echo "  dirs - $octdirs"
echo "  exec - $octexec"
echo "  nxec - $octnxec"
while :; do
  echo "Do you wish to proceed? [Y]es/[N]o: "
  read yn
  case $yn in
    Yes | yes | y | Y) break ;;
    No | no | n | N)
      echo "Cancelled."
      exit 1
      ;;
  esac
done

echo "================================================================================" >> fixperms.log
echo -n "fixperms.sh procceding at " >> fixperms.log
date >> fixperms.log
echo "Setting mask to $octexec or $octnxec based on type or shebang" >> fixperms.log
echo "================================================================================" >> fixperms.log
echo "Setting permissions for directories" >> fixperms.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
find . \( -path ./go/src -o -name .snapshot -o -name .git -o -name .ssh\* -o -name .vnc \) -prune -o -type d -exec chmod -v $octdirs {} \; | grep -v " retained as" >> fixperms.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
echo "Setting permissions for regular files which ARE currently executable" >> fixperms.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
find . \( -path ./go/src -o -name .snapshot -o -name .git -o -name .ssh\* -o -name .vnc -o -name .hsd -o -name .Xauthority \) -prune -o -type f -perm /111 -exec sh -c 'file "{}" | grep -q -v "executable" && echo "File {} is executable but has no shebang"; chmod -v $octexec "{}" | grep -v " retained as" >> fixperms.log' \; | tee fixperms_checkExecBit.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
echo "Setting permissions for regular files which are NOT currently executable" >> fixperms.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
find . \( -path ./go/src -o -name .snapshot -o -name .git -o -name .ssh\* -o -name .vnc -o -name .hsd -o -name .Xauthority \) -prune -o -type f \! -perm /111 -exec sh -c 'file "{}" | grep -q "executable" && chmod -v $octexec {} || chmod -v $octnxec "{}"' \; | grep -v " retained as" >> fixperms.log
echo "--------------------------------------------------------------------------------" >> fixperms.log
echo -n "Fixperms.sh done at " >> fixperms.log
date >> fixperms.log
echo "================================================================================" >> fixperms.log

unset octnxec
unset octexec
unset octcirs
