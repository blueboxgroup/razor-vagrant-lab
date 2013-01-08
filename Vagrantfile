# -*- mode: ruby -*-
# vi: set ft=ruby :

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'berkshelf/vagrant'

require 'lab/helpers'
require 'lab/vagrant_middleware'

# razor node and router/dhcp server
def build_razor_node(config)
  config.vm.define :razor do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "razor.razornet.local"
    vm_config.vm.network :hostonly, razor_ip

    vm_config.vm.provision :chef_solo do |chef|
      chef.data_bags_path = "data_bags"

      chef.run_list = [
        "recipe[router]",
        "recipe[dhcp]",
        "recipe[djbdns::internal_server]",
        "recipe[djbdns::cache]",
        "recipe[razor]"
      ]

      chef.json = {
        :dhcp => {
          :interfaces => [ "eth1" ]
        },
        :djbdns => {
          :domain => 'razornet.local',
          :public_dnscache_ipaddress => razor_ip,
          :public_dnscache_allowed_networks => [ "172.16.33" ],
          :tinydns_internal_resolved_domain => 'razornet.local'
        },
        :razor => {
          :bind_address => razor_ip,
          :images => {
            "rz_mk_#{mk_type}-image.#{mk_version}" => {
              'type' => 'mk',
              'url' => "#{mk_url_prefix}/rz_mk_#{mk_type}-image.#{mk_version}.iso"
            }
          }
        }
      }
    end
  end
end

# create some razor client nodes
def build_client_nodes(config)
  razor_nodes.to_i.times do |i|
    config.vm.define :"node#{i+1}" do |vm_config|
      vm_config.vm.box      = "blank-amd64"
      vm_config.vm.box_url  = "https://s3.amazonaws.com/fnichol/vagrant-base-boxes/blank-amd64-20121109.box"

      unless ENV['NO_GUI']
        vm_config.vm.boot_mode = 'gui'
      end

      # generate a new mac address for each node, to make them unique
      vm_config.vm.customize ["modifyvm", :id, "--macaddress1", "auto"]

      # put primary network interface into hostonly network segement
      vm_config.vm.customize ["modifyvm", :id, "--nic1", "hostonly"]
      vm_config.vm.customize ["modifyvm", :id, "--hostonlyadapter1", "vboxnet0"]

      # pxe boot the node
      vm_config.vm.customize ["modifyvm", :id, "--boot1", "net"]
    end
  end
end

# chef server for the razor chef broker
def build_chef_node(config)
  config.vm.define :chef do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "chef.razornet.local"
    vm_config.vm.network :hostonly, chef_server_ip

    vm_config.vm.customize ["modifyvm", :id, "--cpus", 2]
    vm_config.vm.customize ["modifyvm", :id, "--memory", 1024]

    # create a cache directory outside the virtual machine to cache the large
    # omnibus package across vm creates/destroys
    config.vm.share_folder "cache", "/tmp/chef-vagrant-cache",
      chef_host_cache_dir, :create => true

    vm_config.vm.provision :chef_solo do |chef|
      chef.log_level = :debug
      chef.provisioning_path = "/tmp/chef-vagrant-cache"

      chef.run_list = [
        "recipe[chef-server::default]"
      ]

      chef.json = {
        'chef-server' => {
          'package_checksum' =>
            "e85aae8f0a9b188cf585d86586d139b7094002cc0e05b65300e1634d2f9b28d8"
        }
      }
    end

    vm_config.vm.provision :shell, :inline => <<-POSTINSTALL.gsub(/^ {6}/, '')
      banner()  { printf -- "-----> $*\n"; }

      server_dir=/vagrant/tmp/chef_server

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
        /usr/bin/knife configure --initial \
          --server-url http://127.0.0.1:8000 \
          --user root \
          --repository "" \
          --admin-client-name chef-webui \
          --admin-client-key /etc/chef-server/chef-webui.pem \
          --validation-client-name chef-validator \
          --validation-key /etc/chef-server/chef-validator.pem \
          --defaults --yes
      fi

      if [ ! -d "$server_dir" ] ; then
        banner "Creating $server_dir directory"
        mkdir -p $server_dir
      fi

      banner "Coping chef-validator.pem into tmp/chef_server/"
      cp -f /etc/chef-server/chef-validator.pem $server_dir/
    POSTINSTALL
  end
end

# puppetmaster for the razor puppet broker
def build_puppet_node(config)
  config.vm.define :puppet do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "puppet.razornet.local"
    vm_config.vm.network :hostonly, puppetmaster_ip

    vm_config.vm.provision :chef_solo do |chef|
      chef.run_list = [
        "recipe[puppet::master]"
      ]

      chef.json = {
        :puppet => {
          :master_conf => {
            :master => {
              :autosign => 'true'
            }
          }
        }
      }
    end

    # set up all puppet nodes to be an apache web server
    vm_config.vm.provision :shell, :inline => <<-PREPARE_MASTER.gsub(/^ {6}/, '')
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
    PREPARE_MASTER
  end
end

Vagrant::Config.run do |config|
  include Lab::Helpers

  build_razor_node(config)
  build_chef_node(config)
  build_puppet_node(config)
  build_client_nodes(config)
end
