subnet      = "172.16.33.0/24"
masquerade  = "iptables -t nat -A POSTROUTING -s #{subnet} -o eth0 -j MASQUERADE"

execute "Enable IPv4 forwarding in /etc/sysctl.conf" do
  command   "sed -ie 's/^#\(net.ipv4.ip_forward=1\)$/\1/' /etc/sysctl.conf"
  not_if    "grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf >/dev/null"
end

execute "Enable IPv4 forwarding on running node" do
  command   "sysctl -w net.ipv4.ip_forward=1"
  not_if    "sysctl net.ipv4.ip_forward | grep -q '= 1$' >/dev/null"
end

execute "Add iptables masquerading to /etc/rc.local" do
  command   "sed -ie 's|^\\(exit 0\\)$|#{masquerade}\\n\\n\\1|' /etc/rc.local"
  not_if    "grep -q 'iptables .* MASQUERADE' /etc/rc.local >/dev/null"
end

execute "Enable iptables masquerading on running node" do
  command   masquerade
  not_if    "iptables -L | grep -q '#{subnet}.*ESTABLISHED' >/dev/null"
end
