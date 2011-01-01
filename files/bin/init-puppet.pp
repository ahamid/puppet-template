# we need git and puppet
package {
  'git': ensure => installed;
  'puppet': ensure => installed;
}

# we need a git user.  set the home to /var/get, it will be dedicated
# to the git puppet repo.
user { "git":
  ensure => "present",
  home => "/var/git",
}

# more git user home stuffs...
# * git user home dir
# * puppet subdir for git repo
# * slam in the post-receive hook content that checks the repo out into /etc/puppet
# * init the git repo
# * make sure that the /etc/puppet dir is present (should come with the puppet package) and owned by git group
#   so git can overwrite it on push
file {
  "/var/git":
    ensure => directory,
    owner => git, 
    require => User['git'];
  "/var/git/puppet":
    ensure => directory,
    owner => git, 
    require => File['/var/git'];
  '/var/git/puppet/hooks/post-receive':
    owner => git,
    mode => 755,
    content => "#!/bin/sh\ngit archive --format=tar HEAD | (cd /etc/puppet && tar xf -)", # this should eventually get overwritten with the file from puppet
    require => Exec["Create client puppet Git repo"]; #File['/var/git/puppet/HEAD']; # created by exec "Create client puppet Git repo"
  '/var/git/.ssh':
     ensure => directory,
     owner => git,
     group => git,
     mode => 600,
     require => File['/var/git'];
  '/etc/puppet':
    ensure => directory,
    group => git,
    mode => 664,
    require => [Package['puppet'], User['git']];
}

# comfort us that the right authorized key is making it through to our precious precious root acct
notice "Using SSH public key from environment: $ssh_pub_key\n"

# don't work so gud
# bug as of puppet 0.25 that requires us to actually save the key as 'root' and not target ('git') user
ssh_authorized_key {
  'git':
    ensure => present,
    # set on command line with FACTER_SSH_PUB_KEY=...
    key => "$ssh_pub_key",
    user => 'root',
    name => 'ssh public key from initial puppet config',
    target => '/var/git/.ssh/authorized_keys',
    type => rsa,
    require => File['/var/git/.ssh'],
}

file {
 # grrr...puppet
 # can't set ssh_authorized_key as target user since it tries to back up and fails
 # so have to do it as root then change the permissions
 # this just changes the file permissions so that it's owned by git
 '/var/git/.ssh/authorized_keys':
   ensure => file,
   owner => git,
   group => git,
   mode  => 600,
   require => [User["git"], Ssh_authorized_key['git']];
}

# create the git puppet repo on the node
exec { "Create client puppet Git repo":
  cwd => "/var/git/puppet",
  user => "git",
  command => "/usr/bin/git --bare init",
  creates => "/var/git/puppet/HEAD",
  require => [File["/var/git/puppet"], Package["git"], User["git"]],
}
