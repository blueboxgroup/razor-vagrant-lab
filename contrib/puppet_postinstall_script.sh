#!/usr/bin/env bash
set -e

if ! puppet module list | grep -q puppetlabs-apache >/dev/null ; then
  puppet module install puppetlabs-apache
fi

if [ ! -f /etc/puppet/manifests/site.pp ] ; then
  cat <<SITE_PP > /etc/puppet/manifests/site.pp
node default {
  class { 'apache': }
}
SITE_PP
fi
