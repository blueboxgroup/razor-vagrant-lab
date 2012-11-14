# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'berkshelf/vagrant'

def oc_box_url(name)
  "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/#{name}.box"
end

def razor_ip
  "172.16.33.11"
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

Vagrant::Config.run do |config|
  config.vm.define :razor do |vm_config|
    vm_config.vm.box      = "opscode-ubuntu-12.04"
    vm_config.vm.box_url  = oc_box_url(vm_config.vm.box)

    vm_config.vm.host_name = "razor.vagrantup.com"
    vm_config.vm.network :hostonly, razor_ip

    config.vm.provision :chef_solo do |chef|
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

  # create some razor client nodes
  3.times do |i|
    config.vm.define :"node#{i+1}" do |vm_config|
      vm_config.vm.box        = "blank-amd64"

      unless ENV['NO_GUI']
        vm_config.vm.boot_mode = 'gui'
      end

      # put primary network interface into hostonly network segement
      vm_config.vm.customize ["modifyvm", :id, "--nic1", "hostonly"]
      vm_config.vm.customize ["modifyvm", :id, "--hostonlyadapter1", "vboxnet0"]

      # pxe boot the node
      vm_config.vm.customize ["modifyvm", :id, "--boot1", "net"]
    end
  end
end
