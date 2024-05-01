#!/usr/bin/env bash
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $
# shellcheck shell=sh

# Loops any .will.* files in mystuff/home and injects them into the dotfiles
# NOTE: limited to posix-complaint RC files, other rc files are handled by Install_from_dir.sh

# REMOVED checks for old installs, not finding use for that support

detect_sub_dotfile() {
  dotfile=$1
  if [ -f "$dotfile"."$USER" ]; then
    if result=$(grep -E '(^|^[^#]+;)[ \t]*(source|\.).*(\$USER|'"$USER"')' $dotfile); then
      echo "$dotfile.$USER exists and it (or $dotfile.\$USER) is already included in $dotfile:"
      echo "  $result"
      echo "  would you like to inject the mystuff include there instead?"
    fi
    if get_yn; then
      dotfile="$dotfile.$USER"
    fi
  fi
}

##############################
# Path Finder & Sanity checks
##############################
sanity_checks_ok=0
if ! . "$(readlink -e "$(dirname "$0")")"/Sanity_checks.sh || [ $sanity_checks_ok -ne 1 ]; then
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

# use realinstdir here because instdir has been string-ified for injections
for includefile in "$realinstdir"/.will.*; do
  # Figure out the base name of the target dotfile
  dotfile=${HOME}/${includefile##*.will}

  snippet=/tmp/"$dotfile".snip.$$

  # Generate the expected include snippet regardless
  {
    echo "if [ -f \"$includefile\" ]; then"
    echo "    . \"$includefile\""
    echo "fi"
  } > "$snippet"

  # Flags for moving files around after this logic
  addref=0
  waterfall=0

  # Now check if the base dotfile actually exists
  if [ -f "$dotfile" ]; then
    # Redirect to a user-level file if applicable
    dotfile=$(detect_sub_dotfile "$dotfile")

    # Now check for existing inclusion
    snipexists=0
    # Most accurate method - diff that supports -w & line formats
    if diff -w --new-line-format="" "$snippet" "$snippet"; then
      if [ -n "$(diff -w "$snippet" "$dotfile")" ]; then
        echo "Existing include in $dotfile, no changes needed"
      else
        snipexists=1
      fi
    fi

    # If no exact include found grep for a possible match
    if [ $snipexists -ne 1 ]; then
      if result=$(grep -E '(^|^[^#]+;)[ \t]*(source|\.).*'"$includefile"); then
        echo "Possible existing include in $dotfile:"
        grep -H -C2 -E '(^|^[^#]+;)[ \t]*(source|\.).*'"$includefile"
        echo "Should look like:"
        cat "$snippet"
        echo "ACTION REQUIRED: manually merge $dotfile.snippet into $dotfile if required"
        addref=1
      else
        echo "attempting to update $dotfile"

        # Convert includefile to $HOME based path
        includefile='$HOME'"${includefile##"$realhome"}"

        safe_cp "$dotfile" "$dotfile".new

        cat "$snippet" >> "$dotfile".new

        waterfall=1
      fi
    fi
  else
    echo "Creating a $dotfile to source $includefile"
    safe_cp "$snippet" "$dotfile"
  fi

  if [ $addref -eq 1 ]; then
    safe_cp "$snippet" "$dotfile".snippet
  fi

  if [ $waterfall -eq 1 ]; then
    safe_cp "$dotfile" "$dotfile".old && mv "$dotfile".new "$dotfile" && echo "$dotfile updated, PLEASE DIFF against ${dotfile}.old" || echo "Issue updating $dotfile"
    echo
  elif [ -f "$dotfile".new ]; then
    echo "$dotfile changes were made but NOT applied, please review ${dotfile}.new and update"
    echo
  fi

  rm "$snippet"
done

exit 0
