#!/bin/bash
# <UDF name="fqdn" Label="Fully qualified host name"/>
# <UDF name="root_pub_key" Label="Root public key"/>
# <UDF name="puppet_server" Label="Puppet server ip address"/>

# This script can be used to install basic pre-requisites for git and puppet usage
# It can be used as a Linode stackscript, but can also be run separately
# If you run it separately remember to specify the variables described above:
# * FQDN - fully qualified domain name; omit to omit settings the hostname (i.e. because you already did this yourself...)
# * ROOT_PUB_KEY - a public key to add to the root authorized_keys.  If this is a virgin node, chances are you better do this.  Omit if you don't want
#   this script monkeying with your root key and password
# * PUPPET_SERVER - fuhgeddaboudit, this was used to set up the puppetd server, but that was before I ditched client/server and just went with git

# THIS SCRIPT WILL RANDOMIZE YOUR ROOT PASSWORD.  DON'T BLAME ME IF YOU RUN UNTRUSTED CODE YOU HAVEN'T READ. <3 :)

# redirect all output to a log file
# (if you have problems with this command remove the tee and subshell... can't be arsed to disect this...)
exec >(tee /tmp/stackscript.log) 2>&1

RPMFORGE_RPM_URL=http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.1-1.el5.rf.i386.rpm
EPEL_RPM_URL=http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm

RPMFORGE_KEY="
The following public key can be used to verify RPM packages
downloaded from  http://dag.wieers.com/apt/  using 'rpm -K'
if you have the GNU GPG package.
Questions about this key should be sent to:
Dag Wieers <dag@wieers.com>

-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.2.1 (GNU/Linux)

mQGiBD9JMT0RBAC9Q2B0AloUMTxaK73sD0cOu1MMdD8yuDagbMlDtUYA1aGeJVO6
TV02JLGr67OBY+UkYuC1c3PUwmb3+jakZd5bW1L8E2L705wS0129xQOZPz6J+alF
5rTzVkiefg8ch1yEcMayK20NdyOmhDGXQXNQS8OJFLTIC6bJs+7MZL83/wCg3cG3
3q7MWHm3IpJb+6QKpB9YH58D/2WjPDK+7YIky/JbFBT4JPgTSBy611+bLqHA6PXq
39tzY6un8KDznAMNtm+NAsr6FEG8PHe406+tbgd7tBkecz3HPX8nR5v0JtDT+gzN
8fM3kAiAzjCHUAFWVAMAZLr5TXuoq4lGTTxvZbwTjZfyjCm7gIieCu8+qnPWh6hm
30NgA/0ZyEHG6I4rOWqPks4vZuD+wlp5XL8moBXEKfEVOMh2MCNDRGnvVHu1P3eD
oHOooVMt9sWrGcgxpYuupPNL4Uf6B6smiLlH6D4tEg+qCxC17zABI5572XJTJ170
JklZJrPGtnkPrrKMamnN9MU4RjGmjh9JZPa7rKjZHyWP/z/CBrQ1RGFnIFdpZWVy
cyAoRGFnIEFwdCBSZXBvc2l0b3J5IHYxLjApIDxkYWdAd2llZXJzLmNvbT6IWQQT
EQIAGQUCP0kxPQQLBwMCAxUCAwMWAgECHgECF4AACgkQog5SFGuNeeYvDQCeKHST
hIq/WzFBXtJOnQkJGSqAoHoAnRtsJVWYmzYKHqzkRx1qAzL18Sd0iEYEEBECAAYF
Aj9JMWAACgkQoj2iXPqnmevnOACfRQaageMcESHVE1+RSuP3txPUvoEAoJAtOHon
g+3SzVNSZLn/g7/Ljfw+uQENBD9JMT8QBACj1QzRptL6hbpWl5DdQ2T+3ekEjJGt
llCwt4Mwt/yOHDhzLe8SzUNyYxTXUL4TPfFvVW9/j8WOkNGvffbs7g84k7a5h/+l
IJTTlP9V9NruDt1dlrBe+mWF6eCY55OFHjb6nOIkcJwKxRd3nGlWnLsz0ce9Hjrg
6lMrn0lPsMV6swADBQP9H42sss6mlqnJEFA97Fl3V9s+7UVJoAIA5uSVXxEOwVoh
Vq7uECQRvWzif6tzOY+vHkUxOBRvD6oIU6tlmuG3WByKyA1d0MTqMr3eWieSYf/L
n5VA9NuD7NwjFA1kLkoDwfSbsF51LppTMkUggzwgvwE46MB6yyuqAVI1kReAWw+I
RgQYEQIABgUCP0kxPwAKCRCiDlIUa4155oktAKDAzm9QYbDpk6SrQhkSFy016BjE
BACeJU1hpElFnUZCL4yKj4EuLnlo8kc=
=mqUt
-----END PGP PUBLIC KEY BLOCK-----"

EPEL_KEY="
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.2.6 (GNU/Linux)

mQGiBEXopTIRBACZDBMOoFOakAjaxw1LXjeSvh/kmE35fU1rXfM7T0AV31NATCLF
l5CQiNDA4oWreDThg2Bf6+LIVTsGQb1V+XXuLak4Em5yTYwMTVB//4/nMxQEbpl/
QB2XwlJ7EQ0vW+kiPDz/7pHJz1p1jADzd9sQQicMtzysS4qT2i5A23j0VwCg1PB/
lpYqo0ZhWTrevxKMa1n34FcD/REavj0hSLQFTaKNLHRotRTF8V0BajjSaTkUT4uk
/RTaZ8Kr1mTosVtosqmdIAA2XHxi8ZLiVPPSezJjfElsSqOAxEKPL0djfpp2wrTm
l/1iVnX+PZH5DRKCbjdCMLDJhYap7YUhcPsMGSeUKrwmBCBJUPc6DhjFvyhA9IMl
1T0+A/9SKTv94ToP/JYoCTHTgnG5MoVNafisfe0wojP2mWU4gRk8X4dNGKMj6lic
vM6gne3hESyjcqZSmr7yELPPGhI9MNauJ6Ob8cTR2T12Fmv9w03DD3MnBstR6vhP
QcqZKhc5SJYYY7oVfxlSOfF4xfwcHQKoD5TOKwIAQ6T8jyFpKbQkRmVkb3JhIEVQ
RUwgPGVwZWxAZmVkb3JhcHJvamVjdC5vcmc+iGQEExECACQFAkXopTICGwMFCRLM
AwAGCwkIBwMCAxUCAwMWAgECHgECF4AACgkQEZzANiF1IfabmQCgzvE60MnHSOBa
ZXXF7uU2Vzu8EOkAoKg9h+j0NuNom6WUYZyJQt4zc5seuQINBEXopTYQCADapnR/
blrJ8FhlgNPl0X9S3JE/kygPbNXIqne4XBVYisVp0uzNCRUxNZq30MpY027JCs2J
nL2fMpwvx33f0phU029vrIZKA3CmnnwVsjcWfMJOVPBmVN7m5bGU68F+PdRIcDsl
PMOWRLkTBZOGolLgIbM4719fqA8etewILrX6uPvRDwywV7/sPCFpRcfNNBUY+Zx3
5bf4fnkaCKxgXgQS3AT+hGYhlzIqQVTkGNveHTnt4SSzgAqR9sSwQwqvEfVtYNeS
w5rDguLG41HQm1Hojv59HNYjH6F/S1rClZi21bLgZbKpCFX76qPt8CTw+iQLBPPd
yoOGHfzyp7nsfhUrAAMFB/9/H9Gpk822ZpBexQW4y3LGFo9ZSnmu+ueOZPU3SqDA
DW1ovZdYzGuJTGGM9oMl6bL8eZrcUBBOFaWge5wZczIE3hx2exEOkDdvq+MUDVD1
axmN45q/7h1NYRp5GQL2ZsoV4g9U2gMdzHOFtZCER6PP9ErVlfJpgBUCdSL93V4H
Sgpkk7znmTOklbCM6l/G/A6q4sCRqfzHwVSTiruyTBiU9lfROsAl8fjIq2OzWJ2T
P9sadBe1llUYaow7txYSUxssW+89avct35gIyrBbof5M+CBXyAOUaSWmpM2eub24
0qbqiSr/Y6Om0t6vSzR8gRk7g+1H6IE0Tt1IJCvCAMimiE8EGBECAA8FAkXopTYC
GwwFCRLMAwAACgkQEZzANiF1IfZQYgCgiZHCv4xb+sTHCn/otc1Ovvi/OgMAnRXY
bbsLFWOfmzAnNIGvFRWy+YHi
=MMNL
-----END PGP PUBLIC KEY BLOCK-----"

function install_root_key() {
  echo "Installing root key and setting strong random root password"
  mkdir -p $HOME/.ssh
  chmod og-rwx $HOME/.ssh
  echo "$ROOT_PUB_KEY" > /root/.ssh/authorized_keys
  chmod og-rwx $HOME/.ssh/authorized_keys

  # install package that provides mkpasswd
  yum -y install expect

  # set a random complex password
  mkpasswd -l 64 -d 4 -c 4 -C 4 -s 4 root
}

# internets warn against yum_priority plugin... no longer used
function set_yum_priority() {
  local priority=$2
  local filename=$2
  shift
  shift  
  for repo in $@; do
    echo "Setting repo '$repo' in file '$filename' to priority '$priority'"
    sed -i -e "s/\[$repo\]/\[$repo\]\npriority=$priority/" $filename
  done
}

# internets warn against yum_priority plugin... no longer used
function install_yum_priority() {
  echo "Installing yum-priorities"
  yum -y install yum-priorities
  # "The recommended settings are:
  # [base], [addons], [updates], [extras] ... priority=1 
  #[centosplus],[contrib] ... priority=2
  # Third Party Repos such as rpmforge ... priority=N  (where N is > 10 and based on your preference)"
  if ! grep -q "^ *enabled *= *1" /etc/yum/pluginconf.d/priorities.conf; then
    echo "Yum priorities plugin not enabled by default!"
    exit 1
  fi

  set_yum_priority 1 "/etc/yum.repos.d/CentOS-Base.repo" base addons updates extras
  set_yum_priority 2 "/etc/yum.repos.d/CentOS-Base.repo" centosplus contrib
}

# Install an RPM repository rpm
function install_repo_rpm() {
  local key="$1"
  local url="$2"

  local keyfile
  if ! keyfile=$(mktemp); then
    echo "Error creating temp key file"
    exit 1
  fi

  local rpmfile
  if ! rpmfile=$(mktemp); then
    echo "Error creating temp rpm file"
    exit 1
  fi

  echo "$key" > $keyfile
  rpm --import $keyfile

  wget -O $rpmfile "$url"
  if ! rpm --checksig $rpmfile; then
    echo "rpm signature does not check out!"
    exit 2
  fi

  rpm -i $rpmfile
}

# Install root ssh key
if [ -n "$ROOT_PUB_KEY" ]; then
  echo "Installing root key and random root password"
  install_root_key
fi

# Install RPMForge and yum-priorities plugin
# see: http://wiki.centos.org/AdditionalResources/Repositories/RPMForge
#install_yum_priorities

#echo "Installing RPMForge repo"
#install_repo_rpm "$RPMFORGE_KEY" $RPMFORGE_URL

echo "Installing EPEL repo"
install_repo_rpm "$EPEL_KEY" $EPEL_RPM_URL

#set_yum_priority 3 "/etc/yum.repos.d/rpmforge.repo" rpmforge
#set_yum_priority 3 "/etc/yum.repos.d/epel.repo" epel

yum check-update

echo "Installing puppet"

# holdover from puppetd setup
#echo -e "$PUPPET_SERVER\tpuppet" >> /etc/hosts

yum -y install puppet

yum -y install ruby-rdoc

if [ -n "$FQDN" ]; then
  echo "Setting hostname to $FQDN"
  hostname $FQDN
fi

#puppetd -t

# make sure the puppet service is turned off, we will use a cron job instead
chkconfig --level 123456 puppet off

# set up a cron job to poll every minute - until puppet is bootstrapped and reconfigures this node
echo "* * * * * root /usr/bin/puppet --templatedir /etc/puppet/templates --no-daemonize --logdest syslog /etc/puppet/manifests/site.pp > /dev/null 2>&1" > /etc/cron.d/puppet

