# -*- encoding: utf-8 -*-

module Lab

  module Helpers

    def oc_box_url(name)
      "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/#{name}.box"
    end

    def razor_ip
      "172.16.33.11"
    end

    def chef_server_ip
      "172.16.33.21"
    end

    def puppetmaster_ip
      "172.16.33.31"
    end

    def mk_type
      ENV["MK_TYPE"] || "prod"
    end

    def mk_version
      ENV["MK_VERSION"] || "0.9.3.0"
    end

    def mk_url_prefix
      ENV["MK_URL_PREFIX"] ||
        "https://github.com/downloads/puppetlabs/Razor-Microkernel"
    end

    def razor_nodes
      ENV["RAZOR_NODES"] || 3
    end

    def chef_host_cache_dir
      File.join(File.dirname(__FILE__), %w{.. .. tmp chef_cache})
    end
  end
end
