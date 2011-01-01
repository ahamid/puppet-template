Puppet Template
===============

This is a simple project that encapsulates the default setup for Puppet I have used on a couple of projects.  The approach is derived (take directly) from Bitfield Consulting's "Scaling Puppet with Git" article:

http://bitfieldconsulting.com/scaling-puppet-with-distributed-version-control

This project contains a set of scripts to bootstrap a new machine (whether in a service like Linode or EC2, or a new physical server) into the Git/Puppet setup.

*

(As a side note, I have previously used puppet in a standard client/server deployment architecture, and still do in one case.  However just using Git simplifies the number of moving parts, and reusing standard Git/SSH connections eliminates introducing new variables that might affect security)



Known Issues
============

* the git commit hook attempts to replace `/etc/puppet` content; it cannot completely succeed at this (at least on CentOS/RedHat systems) as the `/etc/puppet/ssl` dir is owned by root
* initial hostname setup is a bit of a mystery.  the init process gets this from somewhere (either scraping '/etc/hosts' or the '/etc/sysconfig/network' file).  I do not set my hostname in the `ifcfg-eth0.erb` template or `/etc/sysconfig/network` file.  If you do not store host names in your `/etc/hosts` then presumably the hostname that is set on initial setup is transient and may not be correct upon reboot.
