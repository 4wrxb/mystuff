#!/bin/sh

errorcount=0

while :; do
  case $1 in
    --)
      printf '  break switch, no more to process'
      shift
      set remaining_args = "$@"
      break
      ;;
    --*)
      if [ -n "$2" ] && [ "$2" = "${2#-}" ]; then
        printf '  word switch "%s" followed by argument "%s".\n' ${1#--} $2
        shift
      else
        printf 'ERROR: word switch %s must be followed by an argument.\n' ${1#--}
        errorcount=$((errorcount + 1))
      fi
      ;;
    -*)
      if [ "${1#-?}" = "" ]; then
        printf '  single letter switch "%s"\n' ${1#-}
      else
        printf 'ERROR: single letter switch "%s" is not a single letter.\n' ${1#-}
        errorcount=$((errorcount + 1))
      fi
      ;;
    -?*)
      printf 'WARNING: unknown option (ignored): %s.\n' "$1"
      ;;
    *)
      if [ -z "$1" ]; then
        printf 'DONE: finished processing arguments with %d errors.\n' $errorcount
        break
      else
        printf 'ERROR: unexected non-switch argument "%s".\n' $1
        errorcount=$((errorcount + 1))
      fi
      ;;
  esac
  shift
done
