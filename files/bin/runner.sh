#!/bin/bash -x
# helper script which can be used to exec stuff from Puppet
# E.g.
# define install-rvm($user, $home) {
#  exec { "install-rvm $user $home" :
#    cwd => "$home",
#    user => "$user",
#    command => "/bin/env -i USER=$user HOME=$home $puppet_root/files/bin/runner.sh install-rvm",
#    creates => "$home/.rvm"
#  }
#}

LOGFILE=/tmp/runner-$arg-$USER.log
{ date; whoami; echo $USER; echo $HOME; env; } >> $LOGFILE

function use_rvm() {
  source "$HOME/.rvm/scripts/rvm" >> $LOGFILE 2>&1
  echo "Using Ruby: $1"  >> $LOGFILE 2>&1
  rvm use $1 >> $LOGFILE 2>&1
}

function install-stow() {
  { date; whoami; echo $USER; echo $HOME; env; } >> /tmp/install-stow.log
  cd /root/downloads &&
  wget http://ftp.gnu.org/gnu/stow/stow-1.3.3.tar.gz &&
  tar -zxf stow-1.3.3.tar.gz &&
  cd stow-1.3.3 &&
  ./configure --prefix=/usr/local && #--prefix=/opt/software/stow-1.3.3 && 
  make clean &&
  make && 
  make prefix=/opt/software/stow-1.3.3 install &&
  cd /opt/software &&
  stow-1.3.3/bin/stow -v -t /usr/local stow-1.3.3
}

function install-rubygems() {
  tmp=$(mktemp -d -t)
  wget -O- http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz | tar -C $tmp -zxf-
  # run RVM since .bashrc is not processed when puppet runs a command as a user
  use_rvm "$1"
  ruby $tmp/rubygems-1.3.7/setup.rb  >> $LOGFILE 2>&1
}

function check-gem() {
  use_rvm "$1"
  shift
  gem list -i $@ >> $LOGFILE 2>&1
}

function install-gem() {
  use_rvm "$1"
  shift
  gem install $@ --no-rdoc >> $LOGFILE 2>&1
}

function install-recordMyDesktop() {
  # TODO implement
  tar -zxf /etc/puppet/files/packages/recordmydesktop-0.3.8.1.tar.gz
  cd recordmydesktop-0.3.8.1
  ./configure --prefix=/usr/local && #--prefix=/opt/software/recordmydesktop-0.3.8.1 && 
  make clean &&
  make && 
  make prefix=/opt/software/recordmydesktop-0.3.8.1 install &&
  cd /opt/software &&
  stow -v -t /usr/local recordmydesktop-0.3.8.1
}

function install-java-service-wrapper() {
  { date; whoami; echo $USER; echo $HOME; env; } >> /tmp/install-jsw.log
  ls -l /opt/software > /tmp/opt-software.tmp
  cd /root/downloads &&
  wget http://wrapper.tanukisoftware.com/download/3.5.6/wrapper-linux-x86-32-3.5.6.tar.gz &&
  tar -zxf wrapper-linux-x86-32-3.5.6.tar.gz &&
  mv wrapper-linux-x86-32-3.5.6 /opt/software/
}

function install-rvm() {
  echo "Downloading and installing RVM..."
  bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head)
  echo "Installing rvm into $HOME/.bashrc..."
  grep -q ".rvm/scripts/rvm" $HOME/.bashrc || echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> $HOME/.bashrc
  echo 'rvm_trust_rvmrcs=0' >> $HOME/.rvmrc # don't trust .rvmrc files
}

# run the args - if the first arg is valid it will call a function of the same name
# if not, bash yields reserved error code 127
"$@"

code=$?

# Reserved: 127 "command not found" illegal_command Possible problem with $PATH or a typo
if [ $? -eq 127 ]; then
  echo "Unknown option: $arg"
  exit 1
else
  echo "$@ - return code: $code" >> $LOGFILE
fi

exit $code
