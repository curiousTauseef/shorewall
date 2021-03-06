require 'set'

case node['platform_family']
when 'rhel'
  include_recipe "yum-epel"
when 'debian'
  # TODO Workaround for shorewall-common bug
  directory "/var/lock/subsys" do
    user 'root'
    group 'root'
    action :create
  end
end

package "shorewall" do
  action :install
end

## TODO: Fix local logic below
zones_per_interface = {}
node['shorewall']['zone_interfaces'].each_pair do |zone, interface|
  if not zones_per_interface.has_key?(interface)
    zones_per_interface[interface] = SortedSet.new
  end
  zones_per_interface[interface].add(zone)
end

default_settings = node['shorewall']['default_interface_settings'].to_hash
zones_per_interface.each_pair do |interface, zones|
  if zones.length > 1
    node.override["shorewall"]["interfaces"] << default_settings.merge({:interface => interface})
    zones.each do |zone|
      zone_hosts = node['shorewall']['zone_hosts'][zone]
      if zone_hosts != nil
        if zone_hosts =~ /^search:(.*)$/
          search_exp = Regexp.last_match(1)
          addresses = get_private_addresses(search_exp).map { |other_node, address| address }.join(',')
        else
          addresses = zone_hosts
        end
        node.override['shorewall']['hosts'] << {:zone => zone, :hosts => "#{interface}:#{addresses}"}
      end
    end
  else
    node.override['shorewall']['interfaces'] << default_settings.merge({:zone => zones.to_a[0], :interface => interface})
  end
end

directory "/etc/shorewall/params.d"

node["shorewall"]["params"].each do |file, data|
  template "/etc/shorewall/params.d/#{file}" do
    source "params.file.erb"
    mode 0600
    owner "root"
    group "root"
    variables( "data" => data )
    notifies :restart, "service[shorewall]", :delayed
  end
end
template "/etc/shorewall/params" do
  source "params.erb"
  mode 0600
  owner "root"
  group "root"
  variables( "files" => node["shorewall"]["params"] )
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/hosts" do
  source "hosts.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/interfaces" do
  source "interfaces.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/policy" do
  source "policy.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/rules" do
  source "rules.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/zones" do
  source "zones.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/masq" do
  source "masq.erb"
  mode 0600
  owner "root"
  group "root"
  notifies :restart, "service[shorewall]", :delayed
end

template "/etc/shorewall/shorewall.conf" do
  only_if { node['shorewall']['enabled'] }
end
if platform_family?('debian')
  template "/etc/default/shorewall" do
    source "shorewall.erb"
    only_if { node['shorewall']['enabled'] }
  end
end

service "shorewall" do
  status_command '/sbin/shorewall status'
  supports [:status, :restart]
  action [:start, :enable]
  only_if { node['shorewall']['enabled'] }
end
