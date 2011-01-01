#!/bin/sh

/usr/bin/puppet -v --templatedir /etc/puppet/templates $@ /etc/puppet/manifests/site.pp
