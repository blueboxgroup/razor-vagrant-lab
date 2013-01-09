site :opscode

cookbook 'razor'

# service dhcp requests
cookbook 'dhcp',        :git => 'git://github.com/fnichol/dhcp-cookbook.git',
                        :branch => 'craigtracey-with-upstart'

# become a router/gateway for razor nodes
cookbook 'router',      :path => './cookbooks-internal/router'

# i heard you liked puppet
cookbook 'puppet'

# chef too? let's party. pinned at 2.0.0 release
cookbook 'chef-server', :git => 'git://github.com/opscode-cookbooks/chef-server.git',
                        :ref => '125e93b5f79284c2aad3c6548d0faead9a0533b2'

cookbook 'djbdns'

# cookbooks which will be installed in your local chef server
group :chef_server do
  cookbook 'apache2'
  cookbook 'chef-client'
end
