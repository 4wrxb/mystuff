#!/bin/false
# shellcheck shell=sh
# shellcheck disable=SC2016 # shfmt uses hard quotes instead of escaping $
# Source this, otherwise sock etc. will not be set

echo "Launching/connecting SSH agent"

# FUTURE: may need to add smarts to handle shared home (e.g. nfs)
agentenv=~/.ssh/agent.env

# shellcheck disable=SC1090 # simple file written from this script
agent_load_env() { test -f "$agentenv" && . "$agentenv" >| /dev/null; }

agent_start() {
  (
    umask 077
    ssh-agent >| "$agentenv"
  )
  # shellcheck disable=SC1090 # simple file written from this script
  . "$agentenv" >| /dev/null
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2=agent not running
agent_run_state=$(
  ssh-add -l >| /dev/null 2>&1
  echo $?
)

if [ ! "$SSH_AUTH_SOCK" ] || [ "$agent_run_state" = 2 ]; then
  agent_start
  ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ "$agent_run_state" = 1 ]; then
  ssh-add
fi

unset env
