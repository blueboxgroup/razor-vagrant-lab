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
        "recipe[apt]",
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
        "recipe[apt]",
        "recipe[chef-server::default]"
      ]

      chef.json = {
        'chef-server' => {
          'package_file' => 'https://opscode-omnitruck-release.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.0-alpha2-1.ubuntu.12.04_amd64.deb',
          'package_checksum' => 'c66e7039495f4ac189400183caa564e5f4ff7dc69bf4fb1835ad674c32cb4883'
        }
      }
    end

    # set up chef server with cookbooks and a web_server role
    vm_config.vm.provision :shell, :inline => postinstall_script(:chef)
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
        "recipe[apt]",
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
    vm_config.vm.provision :shell, :inline => postinstall_script(:puppet)
  end
end

Vagrant::Config.run do |config|
  include Lab::Helpers

  build_razor_node(config)
  build_chef_node(config)
  build_puppet_node(config)
  build_client_nodes(config)
end
