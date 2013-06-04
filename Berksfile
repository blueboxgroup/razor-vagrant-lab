site :opscode

# let's do this right
cookbook 'apt'

cookbook 'razor'

# service dhcp requests
cookbook 'dhcp',        :git => 'git://github.com/spheromak/dhcp-cook.git',
                        :branch => 'dc054895e03c45fea951a7a509aad915512056bd'

# become a router/gateway for razor nodes
cookbook 'router',      :path => './cookbooks-internal/router'

# i heard you liked puppet
cookbook 'puppet'

# chef too? let's party. pinned at a post-2.0.0 release, with URL logging
cookbook 'chef-server', :git => 'git://github.com/opscode-cookbooks/chef-server.git',
                        :ref => '8f8d3558abe7b5e70cc45c940d7ef05dac96f233'

cookbook 'djbdns'

# cookbooks which will be installed in your local chef server
group :chef_server do
  cookbook 'apache2'
  cookbook 'chef-client'
end
