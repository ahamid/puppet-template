# set the root of the checked out puppet config for file source and other references
$puppet_root='/etc/puppet'

# set path so we don't have to fully qualify binaries
Exec {
  path => "/bin:/usr/bin:/usr/local/bin"
}

# Helper to manually construct home dir (on RedHat/CentOS systems)
define user_homedir($homedir="/home/$name") {
  user { "$name":
    ensure => present,
    comment => "$fullname",
    membership => minimum,
    shell => "/bin/bash",
    home => "$homedir"
  }

  exec { "$name homedir":
    command => "/bin/cp -R /etc/skel $homedir; /bin/chown -R $name:$name $homedir",
    creates => "$homedir",
    require => User[$name],
  }
  
  file { "$homedir":
    ensure => directory,
    owner  => "$name",
    group => "$name",
    mode => 700,
    require => Exec["$name homedir"]
  }
}

# we need git (should have a been bootstrapped)
class git {
  package {
    'git': ensure => installed;
  }

  user_homedir { "git" :
    homedir => '/var/git'
  }

  file {
    "/var/git/puppet":
      ensure => directory,
      owner => git, 
      require => File['/var/git'];
    '/var/git/.ssh':
       ensure => directory,
       owner => git,
       group => git,
       mode => 600,
       require => File['/var/git'];
  }

  exec { "Create client puppet Git repo":
    cwd => "/var/git/puppet",
    user => "git",
    command => "/usr/bin/git --bare init",
    creates => "/var/git/puppet/HEAD",
    require => [File["/var/git/puppet"], Package["git"], User_homedir["git"]],
  }
}

# drop down the puppet managed post-receive hook (should have been bootstrapped)
class git-puppet {
  include git
  
  file {
    '/var/git/puppet/hooks/post-receive':
      owner => git,
      mode => 755,
      source => "$puppet_root/files/var/git/puppet/hooks/post-receive",
      require => Exec["Create client puppet Git repo"]; #File['/var/git/puppet/HEAD']; # created by exec "Create client puppet Git repo";
    '/etc/puppet':
      ensure => directory,
      group => git,
      mode => 664,
      require => [Package['puppet'], User['git']];
  }
}

# basic puppet-client class
# includes puppet package and a cron job that runs puppet
class puppet-client {
  include git-puppet

  package { 'puppet':
    ensure => installed
  }

  # install the puppet cron job
  file {
    '/etc/cron.d/puppet':
      owner  => root,
      group  => root,
      mode   => 644,
      source => "$puppet_root/files/etc/cron.d/puppet";
  }
  
  # we don't want this running we cron it ourselves
  service { 'puppet':
    enable => false,
    ensure => 'stopped',
    hasstatus => 'true'
  }
}

# That's it, git and puppet should be set up and you can
# continue to customize this file or configure puppet how you like

############ Sample classes to get you started

# installs scary login warnings
class issue-warnings {
  file {'/etc/issue':
    owner  => root,
    group  => root,
    mode   => 644,
    source => "$puppet_root/files/etc/issue"
  }
  file {'/etc/issue.net':
    owner  => root,
    group  => root,
    mode   => 644,
    source => "$puppet_root/files/etc/issue.net"
  }
}

# set up a basic hosts file so you can easily refer to your nodes internally
# this is probably a good idea since puppet itself needs a reliable way to
# identify the machine it is on
class hosts {
  #host { 'machine1.yourdomain.com':
  #  ip    => '123.123.123.123',
  #  host_aliases => 'machine1'
  #}
}

# sets up static networking so that dhcp client doesn't keep dropping down its own resolve.conf
# see files/etc/resolv.conf to set your domain and search path accordingly
# see templates/network/ifcfg-eth0.erb.  the facter 'ipaddress' fact (already configured via dhcp or otherwise) will be used as the static ip.
# make sure to set the $gateway var on your node definition
class static-networking {
  service { 'network':
    ensure => 'running',
    hasstatus => 'true',
    hasrestart => 'true',
    subscribe  => File['/etc/sysconfig/network-scripts/ifcfg-eth0']
    #restart => '/etc/init.d/network restart'
  }

  file {'/etc/sysconfig/network-scripts/ifcfg-eth0':
    owner   => root,
    group   => root,
    mode    => 644,
    content => template('network/ifcfg-eth0.erb'),
    notify => Service['network']
  }

  file {'/etc/resolv.conf':
    owner  => root,
    group  => root,
    mode   => 644,
    source => "$puppet_root/files/etc/resolv.conf",
    notify => Service['network'] # not sure if we need to restart network service for this
  }
  
  # these seemed to be enabled and running on a CentOS 5.4 box
  service { avahi-daemon:
    enable => false,
    ensure => stopped
  }
  service { avahi-dnsconfd:
    enable => false,
    ensure => stopped
  }
}

# install your ssh config (e.g. move ssh to a non-standard port)
class ssh {
  package { "openssh-server":
    ensure => installed
  }

  file { "/etc/ssh/sshd_config":
    owner  => root,
    group  => root,
    mode   => 600,
    source => "$puppet_root/files/etc/ssh/sshd_config",
  }

  service { sshd:
    ensure     => running,
    hasrestart => true,
    subscribe  => File["/etc/ssh/sshd_config"]
  }
}

# installs iptables firewall rules
# edit these in manifests/network/iptables.erb template
# the template will allow you to perform simple per-node special-casing
class firewall {
  file {'/etc/sysconfig/iptables':
    owner   => root,
    group   => root,
    mode    => 600,
    content => template('network/iptables.erb')
  }
  
  service { iptables:
    enable     => true,
    ensure     => 'running',
    hasstatus  => 'true',
    hasrestart => 'true',
    subscribe  => File["/etc/sysconfig/iptables"]
  }
}

# installs logwatch and settings
class logwatch {
  include mail-transfer-agent

  package { 'logwatch':
    ensure => installed
  }
  file {'/etc/logwatch/conf/override.conf':
    owner  => root,
    group  => root,
    mode   => 644,
    source => "$puppet_root/files/etc/logwatch/conf/override.conf",
    require => Package['logwatch']
  }
}

# installs an aliases file
# ass as files/etc/aliases
class mail-aliases {
  file {'/etc/aliases':
    owner  => root,
    group  => root,
    mode   => 644,
    source => "$puppet_root/files/etc/aliases"
  }
}

# installs postfix.  uses default config which is fine
# for just local or outgoing mail.
class mail-transfer-agent {
  include mail-aliases
  package { 'postfix':
    ensure => installed
  }

  service {
    'postfix':
      enable => true,
      ensure => 'running',
      hasstatus => 'true',
      hasrestart => 'true',
      require => Package['postfix'],
      subscribe => File['/etc/aliases']
  }
}

# basic class that does nothing but get the git+puppet infrastructure
# in place for you
class bootstrap-puppet {
  include puppet-client
}

# class that includes additional configurations
class base-machine {
  include bootstrap-puppet
  include hosts
  include static-networking
  include firewall
  include ssh
  include puppet-client
  include issue-warnings
  include mail-transfer-agent
  include logwatch
}
