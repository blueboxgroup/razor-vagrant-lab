#!/usr/bin/env bash
set -e

banner()  { printf -- "-----> $*\n"; }

server_dir=/vagrant/tmp/chef_server
knife=/usr/bin/knife

for bin in chef-client chef-solo knife ohai shef ; do
  banner "Updating /usr/bin/$bin symlink"
  ln -snf /opt/chef-server/bin/$bin /usr/bin/$bin
done ; unset bin

if [ -d "/opt/chef" ] ; then
  banner "Remove pre-existing Omnibus installation"
  rm -rf /opt/chef
fi

if [ ! -f "/root/.chef/knife.rb" ] ; then
  banner "Creating Chef client key for root user"
  $knife configure --initial \
    --server-url http://127.0.0.1:8000 \
    --user root \
    --repository "" \
    --admin-client-name chef-webui \
    --admin-client-key /etc/chef-server/chef-webui.pem \
    --validation-client-name chef-validator \
    --validation-key /etc/chef-server/chef-validator.pem \
    --defaults --yes
fi

if [ ! -f "/etc/chef-server/.regenerated_validator" ] ; then
  banner "Regenerating chef-validator client key"
  $knife client delete chef-validator -y
  $knife client create chef-validator --admin \
    --file /etc/chef-server/chef-validator.pem --disable-editing
  touch "/etc/chef-server/.regenerated_validator"
fi

if [ ! -d "$server_dir" ] ; then
  banner "Creating $server_dir directory"
  mkdir -p $server_dir
fi

banner "Coping chef-validator.pem into tmp/chef_server/"
cp -f /etc/chef-server/chef-validator.pem $server_dir/

if ! grep -q ^cookbook_path /root/.chef/knife.rb >/dev/null ; then
  banner "Add cookbook_path to /root/.chef/knife.rb"
  grep ^cookbook_path /vagrant/tmp/chef_cache/solo.rb \
    >> /root/.chef/knife.rb
fi

for ckbk in apache2 chef-client ; do
  banner "Uploading $ckbk cookbook to Chef Server"
  $knife cookbook upload $ckbk
done ; unset ckbk

banner "Uploading role[web_server]"
$knife role from file /vagrant/contrib/chef_web_server_role.rb
