#!/usr/bin/env bash
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $

# FIXME: known bashisms: select input method

# Updated "includer" script

oldfilecheck() {
  oldinclude=$1
  if [ -f "$oldinclude" ]; then
    echo "WARNING: An old copy of $(basename "$oldinclude") exists in HOME. New method keeps"
    echo "         these files in the install dir. Would you like to remove the file?"
    echo "         There will be an option to remove the old include (if it exists) later."
    select yn in "Yes" "No" "Disable old file checks"; do
      case $yn in
        Yes)
          rm "$oldinclude"
          return 0
          ;;
        No) return 0 ;;
        "Disable old file checks") return 99 ;;
      esac
    done
  fi
  return 0
}

oldincludecheck() {
  dotfile=$1
  if result=$(\grep '$HOME/.will.' "$dotfile"); then
    if [ "$(\grep -c '$HOME/.will.' "$dotfile")" -gt 2 ]; then
      echo "ERROR: There appears to be mor ethan one old include in $dotfile."
      echo "        The script cannot handle this. Please remove old includes or add it manually."
      return 0
    fi
    echo "WARNING: An old include may be in $dotfile."
    echo "         New method keeps these files in the install dir. Would you like to"
    echo "         replace this old include? Otherwise a new one will be added."
    echo "$result"
    select yn in "Yes" "No" "Disable old include checks"; do
      case $yn in
        Yes) return 1 ;;
        No) return 0 ;;
        "Disable old include checks") return 99 ;;
      esac
    done
  fi
  return 0
}

##############################
# Path Finder & Sanity checks
##############################
sanity_checks_ok=0
if ! . Sanity_checks.sh || [ $sanity_checks_ok -ne 1 ]; then
  echo "The sanity check script failed or could not be found, exiting."
  exit
else
  if [ -z "$homedir" ] || [ -z "$instdir" ] || [ -z "$realhome" ] || [ -z "$realinstdir" ] || [ -z "$externalinstdir" ]; then
    echo "ERROR: the Sanity_checks failed to provide necessary information"
    exit
  fi
fi

##############################
# Now, inject the includes into dotfiles
##############################
# Re-base instdir to $HOME (if it's there)
if [ "$externalinstdir" -ne 1 ]; then
  # By using de-referenced paths here we ensure a mismatch of portable paths is fixed
  instdir='$HOME'"${realinstdir##"$realhome"}"
fi
dooldfilechecks=1
dooldincludechecks=1
# use realinstdir here because instdir has been string-ified for injections
for includefile in "$realinstdir"/.will.*; do
  # Figure out the name of the dotfile
  dotfile=${HOME}/${includefile##*.will}
  # default is to take no actions
  awkit=0
  appendit=0
  waterfall=1
  # Check if the home directory has an old .will.* file (now kept in install dir)
  if [ $dooldfilechecks -eq 1 ]; then
    oldfilecheck "${HOME}/.will${includefile##*.will}"
    if [ $? -eq 99 ]; then
      dooldfilechecks=0
    fi
  fi
  # Now check if the base dotfile actually exists
  if [ -f "$dotfile" ]; then
    echo "attempting to update $dotfile"
    # Now check for an old include
    if [ $dooldincludechecks -eq 1 ]; then
      oldincludecheck "$dotfile"
      case $? in
        99) dooldincludechecks=1 ;;
        0) appendit=1 ;;
        1) awkit=1 ;;
      esac
    else
      # Without old file checks default to append
      appendit=1
    fi
    # Convert includefile to $HOME based path
    includefile='$HOME'"${includefile##"$realhome"}"
    # Now check for ANY .will inclusion except old ones
    if result=$(\grep -v '$HOME/.will.' "$dotfile" | \grep ".will."); then
      echo "WARNING: An include already exists in $dotfile:"
      echo "         Does it match the current install dir ${instdir}?"
      echo "$result"
      echo "         Yes will not make any changes"
      if [ $appendit -eq 1 ]; then
        echo "         No will append a new include, but only into ${dotfile}.new"
      else
        echo "         No will continue updating the old include, but only into ${dotfile}.new"
      fi
      select yn in "Yes" "No"; do
        case $yn in
          Yes)
            echo "$dotfile was not updated"
            echo
            waterfall=0
            awkit=0
            appendit=0
            break
            ;; # Do nothing
          No)
            waterfall=0
            break
            ;;
        esac
      done
    fi
    if [ $awkit -eq 1 ]; then
      # If the user said to update include use awk
      echo "updating existing include in $dotfile"
      awk "{gsub(/\\\$HOME\/.will./,\"$instdir/.will.\"); print}" "$dotfile" > "$dotfile".new
    fi
    if [ $appendit -eq 1 ]; then
      # otherwise, copy the dotfile and append
      \cp -a "$dotfile" "$dotfile".new
      {
        echo
        echo "if [ -f \"$includefile\" ]; then"
        echo "    . \"$includefile\""
        echo "fi"
        echo
      } >> "$dotfile".new
    fi
    if [ $waterfall -eq 1 ]; then
      \cp -ai "$dotfile" "$dotfile".old && mv "$dotfile".new "$dotfile"
      echo "$dotfile updated, PLEASE DIFF against ${dotfile}.old"
      echo
    elif [ -f "$dotfile".new ]; then
      echo "$dotfile changes were made but NOT applied, please review ${dotfile}.new and update"
      echo
    fi
  else
    echo "Creating a $(basename "$dotfile") to source $includefile"
    echo
    {
      echo "if [ -f \"$includefile\" ]; then"
      echo "    . \"$includefile\""
      echo "fi"
      echo
    } > "$dotfile"
  fi
done

exit 0
