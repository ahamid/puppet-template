h1. Puppet Template

h2. Known Issues

* the git commit hook attempts to replace `/etc/puppet` content; it cannot completely succeed at this (at least on CentOS/RedHat systems) as the `/etc/puppet/ssl` dir is owned by root
* initial hostname setup is a bit of a mystery.  the init process gets this from somewhere (either scraping '/etc/hosts' or the '/etc/sysconfig/network' file).  I do not set my hostname in the `ifcfg-eth0.erb` template or `/etc/sysconfig/network` file.  If you do not store host names in your `/etc/hosts` then presumably the hostname that is set on initial setup is transient and may not be correct upon reboot.
