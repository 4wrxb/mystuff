#!/bin/sh
# Inspired by https://randyfay.com/content/reference-cache-repositories-speed-clones-git-clone-reference
# and https://www.drupal.org/sandbox/mfer/1074256

show_help() {
  echo 'monstref.sh
Creates a reference repository for all projects specified in $myprojects from $GIT_REPOS/$proj combined in $TA/monstref.

- $GIT_REPOS is the base of a git repository path with optional protocols/username etc..
- $myprojects is a string of space seperated project (repository) names appended to $GIT_REPOS to populate the monstref.
- $TA is the temp area for the monstref. If $TA is not specified $TMPDIR is tried and finally /tmp is used. However,
  these fall-back options print a warning and prompt to conitnue to ensure the path is known and configured in git.
  NOTE: there is no check to confirm any properties for this path (permissions, filesystem type, or free space).

This "monstref" repo can be specified as an alternate/reference (as $TA/monstref) for git when the main source
repository and/or working tree are remote (or on network storage) to speed git operations.

WARNING: references/alternates can be dangerous as the necessary objects for git are NOT stored in your working tree
         under .git. It is necessary to understand this and recommended to know you have a backup before proceeding.
         This should be relatively safe when based on a public repo (what the durpal script above is doing) since the
         the reference directory can always be replaced/recreated.

Optional switches:
 -h, -?, --help
    Show this help and exit.

 -s "relative/path/to_${proj}_repo", --subdir "relative/path/to_${proj}_repo"
    The path under $GIT_REPOS (see below) where each projects repo is found. This is expected to contain $proj and will
    be evaled for expansion. **WARNING** evals are dangerous and this should be sued with care. An interactive prompt
    will display the string and prompt the user to continue unless -e is specified.

 -e, --evalok
    Supress the prompt to confirm the -p switch contents are safe for eval.

 -p "project list space seperated", --projects "project list space seperated"
    Causes the script to ignore $myprojects and instead use the provided list. See above for format/usage.

 -b "proto://base/gitrepo/path", --base "proto://base/gitrepo/path"
    Causes the script to ignore $GIT_REPOS and instead use the provided string.

 -t "/path/to/tmp/dir", --tmparea "/path/to/tmp/dir"
    Causes the script to ignore $TA and $TMPDIR and uses the provided path instead.
'

  #TODO: details on usage with git?

}

# Initailize variables from environment (if applicable)
subdir=""
evalok=0
projects="$myprojects"
base="$GIT_REPOS"
# Only use TA here, we want to warn on default use
tmparea="$TA"

while :; do
  case $1 in
    -h | -\? | --help)
      show_help
      exit
      ;;
    -s | --subdir)
      if [ -n "$2" ]; then
        repopath=$2
        shift
      else
        printf 'ERROR: "--subdir" requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    -e | --evalok)
      evalok=1
      ;;
    -p | --projects)
      if [ -n "$2" ]; then
        projects=$2
        shift
      else
        printf 'ERROR: "--projects" requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    -b | --base)
      if [ -n "$2" ]; then
        base=$2
        shift
      else
        printf 'ERROR: "--base" requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    -t | --tmparea)
      if [ -n "$2" ]; then
        tmparea=$2
        shift
      else
        printf 'ERROR: "--tmparea" requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *)
      break
      ;;
  esac

  shift
done

# Check for required variables
if [ -z "$base" ]; then
  echo "ERROR: environment variable GIT_REPOS isn't set and --base isn't specified, don't know where to find source repos."
  exit 1
fi

if [ -z "$projects" ]; then
  echo "ERROR: evnironment variable myprojects isn't set and --projects isn't specifed, don't know what projects to refrence."
  exit 1
fi

if [ -z "$repopath" ]; then
  alias repoexp='echo $proj'
else
  if [ $evalok -ne 1 ]; then
    while :; do
      # TODO: move this all to a printf, but for now just make sure repopath is safe
      echo "WARNING: provided subdir argument will be expanded **USING EVAL**. This can be dangerous if contents are unsafe."
      printf '         subdir is set to: %s\n' "$repopath"
      echo '         does this look safe (a relative path with $proj in it)? [y/n]'
      read yn
      case $yn in
        Yes | yes | y | Y) break ;;
        No | no | n | N)
          echo "Canceled"
          exit 1
          ;;
      esac
    done
  fi
  alias repoexp='eval echo $repopath'
fi

proj="test1"
testpath="$(repoexp)"
proj="test2"
if [ "$testpath" = "$(repoexp)" ]; then
  echo 'ERROR: subdir option does not vary with changes to loop variable $proj, this script will not work'
  exit 1
fi

if [ -z "$tmparea" ]; then
  while :; do
    echo "WARNING: environment variable TA isn't set and --tmparea isn't specified."
    if [ -z "$TMPDIR" ]; then
      echo "         Will use /tmp/monstref as the refrence repo."
      tmparea="/tmp"
    else
      printf '         Will use %s/monstref as the reference repo.\n' "$TMPDIR"
      tmparea="$TMPDIR"
    fi
    echo "Continue? [y/n]"
    read yn
    case $yn in
      Yes | yes | y | Y) break ;;
      No | no | n | N)
        echo "Canceled"
        exit 1
        ;;
    esac
  done
fi

# TODO: expand on this?
if [ ! -d $tmparea ] || [ ! -w $tmparea ]; then
  echo "ERROR: tmparea is not an existing, writeable, directory"
  exit
fi

# Make a holding dir if it doesn't exit
[ ! -d "$tmparea/.monstreftmp" ] && mkdir "$tmparea/.monstreftmp"
# Delete this when we're done
trap "\rm -Rf '$tmparea/.monstreftmp'" EXIT

# Make the ref dir if it doesn't exit
[ ! -d "$tmparea/monstref" ] && mkdir "$tmparea/monstref"

# Git stuff is easer in the repo
cd "$tmparea/monstref"

# Init the repo if not done
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  git init --bare
  git config core.compression 1
fi

# Loop through projects
for proj in $(echo $projects); do
  if grep -q "\[ *remote *.$proj" config; then
    # If the project isn't in the remote do nothing at this point, but warn we don't update the reference url.
    printf 'WARNING: %s reference already exists. It will be updated, but the url is NOT checked or updated.\n' "$proj"
  else
    # A big compare is done when adding the reference and fetching, unelss it's a bare repo. So clone bare and add that.
    echo "Adding $proj to monstref via bare clone."
    if git clone --bare "$base/$(repoexp)" "$tmparea/.monstreftmp/$proj"; then
      # Unlike the drupal code the if is more complicated, just fetch as each is added.
      git remote add -f $proj "$tmparea/.monstreftmp/$proj"
      git remote set-url $proj "$base/$(repoexp)"
    else
      echo "ERROR: failed to add $proj, clone of $base/$(repoexp) failed. Details are probably above."
    fi
  fi
done

echo "Fetching all repos to initialize new projects and update existing ones."
git fetch --all
