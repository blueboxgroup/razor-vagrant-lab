# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'berkshelf/vagrant'

def oc_box_url(name)
  "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/#{name}.box"
end

def razor_ip
  "172.16.33.11"
end

def puppetmaster_ip
  "172.16.33.31"
end

def mk_type
  ENV["MK_TYPE"] || "prod"
end

def mk_version
  ENV["MK_VERSION"] || "0.9.2.1"
end

def mk_url_prefix
  ENV["MK_URL_PREFIX"] || "https://github.com/downloads/puppetlabs/Razor-Microkernel"
end

def razor_nodes
  ENV["RAZOR_NODES"] || 3
end

module ClientNode
  def client_node?(env)
    env["vm"].name.to_s =~ /^node\d+/
  end
end

module SkipIfClientNode
  include ClientNode

  def call(env)
    if client_node?(env)
      @env = env
      @app.call(env)
    else
      super
    end
  end
end

# Short-circuit vagrant middlewares that are assuming a normal base box.
# For razor client nodes there is no need to prepare provisioners,
# nfs mounts, etc.
%w[Provision NFS ShareFolders HostName].each do |klass|
  Object.const_set("#{klass}SkipIfClientNode",
    Class.new(Vagrant::Action::VM.const_get(klass)) do
      include SkipIfClientNode
    end
  )

  Vagrant.actions[:start].replace(Vagrant::Action::VM.const_get(klass),
    Object.const_get("#{klass}SkipIfClientNode"))
end

# Short-cicuit the Boot middleware to not wait for an SSH connection.
class BootWithNoSSH < Vagrant::Action::VM::Boot
  include ClientNode

  def call(env)
    if client_node?(env)
      @env = env
      boot
      @app.call(env)
    else
      super
    end
  end
end
Vagrant.actions[:start].replace(Vagrant::Action::VM::Boot, BootWithNoSSH)

Vagrant::Config.run do |config|
  # razor node and router/dhcp server
  config.vm.define :razor do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "razor.vagrantup.com"
    vm_config.vm.network :hostonly, razor_ip

    vm_config.vm.provision :chef_solo do |chef|
      chef.data_bags_path = "data_bags"

      chef.run_list = [
        "recipe[router]",
        "recipe[dhcp]",
        "recipe[razor]"
      ]

      chef.json = {
        :dhcp => {
          :interfaces => [ "eth1" ]
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

  # puppetmaster for the razor puppet broker
  config.vm.define :puppetmaster do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "puppetmaster.vagrantup.com"
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
      puppet module install puppetlabs-apache
      cat <<SITE_PP > /etc/puppet/manifests/site.pp
      node default {
        class { 'apache': }
      }
      SITE_PP
    PREPARE_MASTER
  end

  # create some razor client nodes
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
