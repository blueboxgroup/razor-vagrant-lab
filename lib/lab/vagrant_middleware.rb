# -*- encoding: utf-8 -*-

MIDDLEWARES = [
  Vagrant::Action::Builtin::Provision,
  Vagrant::Action::Builtin::NFS,
  VagrantPlugins::ProviderVirtualBox::Action::ShareFolders,
  Vagrant::Action::Builtin::SetHostname,
  VagrantPlugins::ProviderVirtualBox::Action::CheckGuestAdditions,
  VagrantPlugins::ProviderVirtualBox::Action::Network
].freeze

module Lab

  module ClientNode

    def client_node?(env)
      env[:machine].name.to_s =~ /^node\d+/
    end
  end
end


# patch the living heck out of existing middlewares since vagrant plugins
# are relying action hooks by class name (i.e. subclassing will not work).
#
# NOTE: this is incredibly evil, brittle, not forwards compatible, but it
# works. thanks ruby!
MIDDLEWARES.each do |klass|
  klass.class_eval do

    include Lab::ClientNode

    alias_method :original_call, :call

    def call(env)
      if client_node?(env)
        @env = env
        @app.call(env)
      else
        original_call(env)
      end
    end
  end
end

VagrantPlugins::ProviderVirtualBox::Action::Boot.class_eval do

  include Lab::ClientNode

  alias_method :original_call, :call

  def call(env)
    if client_node?(env)
      @env = env
      boot_mode = @env[:machine].provider_config.gui ? "gui" : "headless"
      # Start up the VM and don't wait for it to boot.
      env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
      env[:machine].provider.driver.start(boot_mode)
      @app.call(env)
    else
      original_call(env)
    end
  end
end
