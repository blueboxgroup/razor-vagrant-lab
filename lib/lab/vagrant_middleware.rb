# -*- encoding: utf-8 -*-

module Lab

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

  class ProvisionSkipIfClientNode < Vagrant::Action::VM::Provision

    include SkipIfClientNode
  end

  class NFSSkipIfClientNode < Vagrant::Action::VM::NFS

    include SkipIfClientNode
  end

  class ShareFoldersSkipIfClientNode < Vagrant::Action::VM::ShareFolders

    include SkipIfClientNode
  end

  class HostNameSkipIfClientNode < Vagrant::Action::VM::HostName

    include SkipIfClientNode
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
end

# Wire in modified middlewares

Vagrant.actions[:start].replace(
  Vagrant::Action::VM::Boot, Lab::BootWithNoSSH)
Vagrant.actions[:start].replace(
  Vagrant::Action::VM::Provision, Lab::ProvisionSkipIfClientNode)
Vagrant.actions[:start].replace(
  Vagrant::Action::VM::NFS, Lab::NFSSkipIfClientNode)
Vagrant.actions[:start].replace(
  Vagrant::Action::VM::ShareFolders, Lab::ShareFoldersSkipIfClientNode)
Vagrant.actions[:start].replace(
  Vagrant::Action::VM::HostName, Lab::HostNameSkipIfClientNode)
