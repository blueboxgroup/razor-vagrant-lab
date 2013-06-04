# -*- mode: ruby -*-
# vi: set ft=ruby :

$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'lab/helpers'
require 'lab/vagrant_middleware'

# razor node and router/dhcp server
def build_razor_node(config)
  config.vm.define :razor do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.hostname = "razor.razornet.local"
    vm_config.vm.network :private_network, :ip => razor_ip

    vm_config.berkshelf.enabled = true

    vm_config.vm.provision :chef_solo do |chef|
      chef.data_bags_path = "data_bags"

      chef.run_list = [
        "recipe[apt]",
        "recipe[router]",
        "recipe[dhcp::server]",
        "recipe[djbdns::internal_server]",
        "recipe[djbdns::cache]",
        "recipe[razor]"
      ]

      chef.json = {
        :dhcp => {
          :networks => ["172-16-33-0_24"],
          :options => {
            'domain-name-servers' => "172.16.33.11",
            'domain-name' => "\"razornet.local\""
          },
          :parameters => {
            'next-server' => "172.16.33.11",
          },
          :interfaces => [ "eth1" ]
        },
        :djbdns => {
          :domain => 'razornet.local',
          :public_dnscache_ipaddress => razor_ip,
          :public_dnscache_allowed_networks => [ "172.16.33" ],
          :tinydns_internal_resolved_domain => 'razornet.local'
        },
        :razor => {
          :app => {
            :git_rev => '7ce9619eb0e9e99be4b714939d4ad4586b3aba7d'
          },
          :bind_address => razor_ip,
          :images => {
            "rz_mk_#{mk_type}-image.#{mk_version}" => {
              'type' => 'mk',
              'url' => mk_url
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

      vm_config.vm.provider "virtualbox" do |virtualbox|
        virtualbox.gui = true unless ENV['NO_GUI']

        # generate a new mac address for each node, to make them unique
        virtualbox.customize ["modifyvm", :id, "--macaddress1", "auto"]

        # put primary network interface into hostonly network segement
        virtualbox.customize ["modifyvm", :id, "--nic1", "hostonly"]
        virtualbox.customize ["modifyvm", :id, "--hostonlyadapter1", "vboxnet0"]

        # pxe boot the node
        virtualbox.customize ["modifyvm", :id, "--boot1", "net"]
      end
    end
  end
end

# chef server for the razor chef broker
def build_chef_node(config)
  config.vm.define :chef do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.hostname = "chef.razornet.local"
    vm_config.vm.network :private_network, :ip => chef_server_ip

    vm_config.vm.provider "virtualbox" do |virtualbox|
      virtualbox.customize ["modifyvm", :id, "--cpus", 2]
      virtualbox.customize ["modifyvm", :id, "--memory", 1024]
    end

    vm_config.vm.provision :chef_solo do |chef|
      chef.log_level = :debug
      chef.provisioning_path = "/vagrant/tmp/chef_cache"

      chef.run_list = [
        "recipe[apt]",
        "recipe[chef-server::default]"
      ]

      chef.json = {
        'chef-server' => {
          'package_file' => 'http://opscode-omnitruck-release.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.4-1.ubuntu.12.04_amd64.deb',
          'package_checksum' => 'f3564ce57e36633c0d92017e6b17ea218c83e954ebfdcdb487eccb0b4c2e4932'
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

    vm_config.vm.hostname = "puppet.razornet.local"
    vm_config.vm.network :private_network, :ip => puppetmaster_ip

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

Vagrant.configure("2") do |config|
  include Lab::Helpers

  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest

  build_razor_node(config)
  build_chef_node(config)
  build_puppet_node(config)
  build_client_nodes(config)
end
