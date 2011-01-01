Puppet Template
===============

This is a simple project that encapsulates the default setup for Puppet I have used on a couple of projects.  The approach is derived (take directly) from Bitfield Consulting's "Scaling Puppet with Git" article:

[Bitfield Consulting - Scaling Puppet with Distributed Version Control]: http://bitfieldconsulting.com/scaling-puppet-with-distributed-version-control

This project contains a set of scripts to bootstrap a new RedHat/CentOS machine (whether in a service like Linode or EC2, or a new physical server) into the Git/Puppet setup.

* bootstrap-machine.sh - this is the first script to run on the machine.  It installs EPEL, git and puppet, optionally sets a hostname and sets a root SSH key (and randomizes the root password), and starts up a puppet job that polls for the initial puppet run.  This script can be run either manually, or as part of a Linode boot Stackscript or EC2 equivalent.
* init-puppet-node.sh/init-puppet.pp - run this to get the rest of the git/puppet machinery in place

The typical workflow is:

1. Provision/install new machine
1. On the target machine arrange to run `bootstrap-machine.sh`.  Either define `FQDN` and `ROOT_PUB_KEY` manually, or configure them however you configure the script to run at boot (e.g. Linode has an interface to define the fields).
    `FQDN=machine1.mydomain.com ./bootstrap-machine.sh`
1. On your desktop, `run init-puppet-node.sh`.  Either configure your name ahead of time, or define the `MACHINE_NAME` env var if you can only access it externally via IP.
   This script will:
   1. SSH into the target machine and perform an initial Puppet run to complete bootstrapping
   1. Reset your git remote based on the machine name to handle the case where your puppet config has changed the ssh port (making git now inaccessible).
   1. Perform your initial git push to to replace a couple of bootstrapped trampoline files with the real puppet-managed source
   You will be prompted at each step.

    `./init-puppet-node.sh machine1.mydomain.com`

From there you can continue on to customize your puppet config.  You can also subsequently bootstrap additional machines this way.  You can manually add additional remotes for each new target to your local repo and push to all of them.

(As a side note, I have previously used puppet in a standard client/server deployment architecture, and still do in one case.  However just using Git simplifies the number of moving parts, and reusing standard Git/SSH connections eliminates introducing new variables that might affect security)



Known Issues
============

* the git commit hook attempts to replace `/etc/puppet` content; it cannot completely succeed at this (at least on CentOS/RedHat systems) as the `/etc/puppet/ssl` dir is owned by root
* initial hostname setup is a bit of a mystery.  the init process gets this from somewhere (either scraping '/etc/hosts' or the '/etc/sysconfig/network' file).  I do not set my hostname in the `ifcfg-eth0.erb` template or `/etc/sysconfig/network` file.  If you do not store host names in your `/etc/hosts` then presumably the hostname that is set on initial setup is transient and may not be correct upon reboot.
