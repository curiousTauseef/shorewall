default["shorewall"]["private_ranges"] = ['192.168.0.0/16', '172.16.0.0/12', '10.0.0.0/8']

default["shorewall"]["enabled"] = true

default["shorewall"]["zone_interfaces"]["lan"] = "eth0"

# If we have both net and lan on one interface, search our hosts to assign them to a zone
default["shorewall"]["zone_hosts"]["lan"] = "search:hostname:[* TO *] AND chef_environment:#{node.chef_environment}"
default["shorewall"]["zone_hosts"]["net"] = "0.0.0.0/0"

# Interface default
default["shorewall"]["default_interface_settings"]["broadcast"] = "detect"
default["shorewall"]["default_interface_settings"]["options"] = "tcpflags,blacklist,routefilter,nosmurfs,logmartians,dhcp"

# zones ordered from most specific to most general
default["shorewall"]["zones"] = [
    {"zone" => "fw", "type" => "firewall"},
    {"zone" => "lan", "type" => "ipv4"}
]

# turn "Off" to deactivate IP_FORWARDING
default["shorewall"]["ip_forwarding"] = "On"

default["shorewall"]["policy"] = [
    {"source" => "fw", "dest" => "all", "policy" => "ACCEPT"},
    {"source" => "lan", "dest" => "fw", "policy" => "REJECT", "log" => "DEBUG"},
    {"source" => "all", "dest" => "all", "policy" => "REJECT"}
]

override["shorewall"]["interfaces"] = [ ]

override["shorewall"]["hosts"] = [ ]

default["shorewall"]["rules"] = [
    { "description" => "Incoming SSH to firewall", "source" => "all", "dest" => "fw", "proto" => "tcp", "dest_port" => 22, "action" => "ACCEPT" },
    { "description" => "Incoming check_mk to firewall", "source" => "lan", "dest" => "fw", "proto" => "tcp", "dest_port" => 6556, "action" => "ACCEPT" }
]