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

    def mk_url
      "#{mk_url_prefix}/#{mk_type}/rz_mk_#{mk_type}-image.#{mk_version}.iso"
    end

    def mk_type
      ENV["MK_TYPE"] || "prod"
    end

    def mk_version
      ENV["MK_VERSION"] || "0.12.0"
    end

    def mk_url_prefix
      ENV["MK_URL_PREFIX"] ||
        "https://downloads.puppetlabs.com/razor/iso"
    end

    def razor_nodes
      ENV["RAZOR_NODES"] || 3
    end

    def chef_host_cache_dir
      File.join(File.dirname(__FILE__), %w{.. .. tmp chef_cache})
    end

    def postinstall_script(which)
      IO.read(File.join(File.dirname(__FILE__),
        %W{.. .. contrib #{which}_postinstall_script.sh}))
    end
  end
end
