#!/bin/sh
# This script initializes/bootstraps a node with minimal git and puppet dependencies.
# After this is run you're ready to start pushing new puppet content to the node to
# further configure it

# change this to match the ultimate SSH port your puppet reconfigures sshd on
FINAL_SSH_PORT=${FINAL_SSH_PORT:-22}

function die() {
  echo "$1" 1>&2
  [ $# -gt 1 ] && exit $2 || exit 1
}

function pause() {
  read -sn 1 -p "$*"
}

# helper to (re)set the remote url, in the case that the initial puppet config
# moves sshd off 22
function set_git_remote_url() {
  local machine_name=$1
  local url=$2

  git remote | grep -q "$machine_name"
  if [ $? -eq 1  ]; then
    echo "Adding git remote '$machine_name' => '$url'"
    git remote add -m master $machine_name $url || die "Error adding git remote"
  else
    echo "Setting git remote '$machine_name' => '$url'"
    git remote set-url $machine_name $url || die "Error setting git remote"
  fi
}


if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) host [init pp]"
  echo
  echo "Your ~/.ssh/id_rsa.pub public key will be used in the absence of a SSH_PUB_KEY env var"
  echo
  exit 1
fi

host="$1"
# if you are using an IP and don't have a public name
# just set MACHINE_NAME in the environment
machine_name=${MACHINE_NAME:-${host%%.*}}
key="$SSH_PUB_KEY"
if [ -n "key" ]; then
  if [ ! -f $HOME/.ssh/id_rsa.pub ]; then
    die "No SSH_PUB_KEY environment variable specified and no $HOME/.ssh/id_rsa.pub file"
  else
    # take the content after space - discard leading type (assume rsa)
    key=$(cut -d ' ' -f 2 $HOME/.ssh/id_rsa.pub)
    echo
    echo -e "Using key from $HOME/.ssh/id_rsa.pub:\n\n$key"
    echo
  fi
fi

# set up the final git remote url
if [ "${FINAL_SSH_PORT}" != "22" ]; then
  host_post=$host:${FINAL_SSH_PORT}
else
  host_post=$host
fi
remote_pre="ssh://git@$host/var/git/puppet"
remote_post="ssh://git@$host_post/var/git/puppet"

# if a non-default bootstrap puppet config was specified, use it
if [ $# -gt 1 ]; then
  INIT_PP="$2"
else
  INIT_PP="init-puppet.pp"
fi

# print the config before we debauch the node
echo
echo -e "\tHostname:        \t$host"
echo -e "\tMachine name:    \t$machine_name"
echo -e "\t$USER's public key:     \t$key"
echo -e "\tRemote Git url (before):\t$remote_pre"
echo -e "\tRemote Git url (after): \t$remote_post"
echo -e "\tBootstrap Puppet file:  \t$INIT_PP"
echo
pause "Initialize node? (y/n) "
echo
[ "$REPLY" != "n" ] || die "Aborted!"

puppet_cmd="puppet -v --"
# sneaky way to get our public key into the Puppet config without hardcoding
# facter, and therefore puppet, exposes env vars preceded with FACTER_
set_key="export FACTER_SSH_PUB_KEY='$key'"

# remove the known ssh host key, assuming we have been testing iteratively
# (and it is getting regenerated)
echo "Removing $host from $HOME/.ssh/known_hosts"
sed --in-place "/${host//\./\\.}/d" $HOME/.ssh/known_hosts

# invoke puppet with the bootstrap config, setting the SSH key in the env
ssh root@$host "$set_key; $puppet_cmd" < $(dirname $0)/$INIT_PP || die "Error running puppet command"

pause "Node initialized.  Perform initial git push? (y/n) "
echo
[ "$REPLY" != "n" ] || die "Initial Git push cancelled!  Manually add the remote and/or push."

# puppet might have moved sshd, so update the git remote
# because doin' that over and over manually gets really tedious...
set_git_remote_url $machine_name $remote_pre

# push your lovely puppet content
git push $machine_name master || die "Error pushing content"

pause "Git content has been pushed.  Press any key to reset remote url."
echo

set_git_remote_url $machine_name $remote_post

echo
echo "Done.  In a few minutes you can log into the node with: 'root@$host_post'!"
echo
