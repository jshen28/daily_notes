# RANDOM THOUGHT ON PROXY ARP

Openstack neutron `dvr` mode relies on proxy arp to provide floating ip service. So I would like to dig in and find out how it implements both in terms of linux and neutron source code. By understanding the basics, it will do great help to understand what is going on under the hood.

## DEMO

In this section, I would like to present you how to do a demo proxy arp in a Unbuntu 16.04 virtual machine. For simplicity I use a network namespace to offer a network isolation. I admit to feel uncomfortable with iptables but nevermind it is not necessary unless you want to really **talk** to the proxied nic.

### PREPARE SYSTEM CONF

```bash
# sysctl could be used to check system configurations
# make sure that following values to be 1
sysctl net.ipv4.conf.${NIC}.proxy_arp
sysctl net.ipv4.ip_forward

# if above is not 1
# then manually set it to 1
# ssyctl -w net.ipv4.conf.all.proxy_arp=1
sysctl -w net.ipv4.conf.${NIC}.proxy_arp=1
sysctl -w net.ipv4.ip_forward=1
```

### NETWORK BIRD VIEW

```raw
# ---------               -----------
# |       |               |         |
# | net 1 |    <------>   |  net 2  |
# | proxy |               |  netns  |
# |       |               |         |
# ---------               -----------
```

### CREATE NETNS & VETH PAIR

```bash
ip netns add ${NS_NAME}
ip link add ${VETH0} type veth peer name ${VETH1}
ip link set ${VETH1} netns ${NS_NAME}

# give them ip addresses
ip addr add ${VETH0_CIRD} dev ${VETH0}
ip link set ${VETH0_CIRD} up
ip netns exec ${NS_NAME} ip addr add ${VETH1_CIRD} dev ${VETH1}
ip netns exec ${NS_NAME} ip link set ${VETH1} up

# test connectivity by ping
ip netns exec ${NS_NAME} ping ${VETH0_ADDR}
```

### SETUP PROXY ARP

```bash
ip route add to ${PROXIED_IPADDR} via ${ANOTHER_IPADDR_ON_VM}

# try arping in another namespace
# install arping if it is not present
ip netns exec ${NS_NAME} arping ${VETH0}
```

### REFERENCES

Threads I've read

* [a good reference on dvr implementation](http://www.cnblogs.com/sammyliu/p/4713562.html)
* [mostly refered to article on dvr and ovs](https://assafmuller.com/2015/04/15/distributed-virtual-routing-floating-ips/)
* [set up proxy arp](https://infosec-neo.blogspot.com/2007/07/how-to-implement-proxy-arp-on-linux-box.html)
* [how to enable/disable proxy arp in linux](http://www.linuxproblem.org/art_8.html)

## IPTABLES USAGES

## NEUTRON CODE ANALYSIS

### ML2 PLUGIN (EXTENSION)

Resource (resource map) are extended by extension plugins.

* neutron manager initialize, `_load_service_plugins`, namespace: `neutron.service_plugins`.
* `L3_ROUTER_NAT` connects extension with service plugin; `neutron.services.l3_router.l3_router_plugin.L3RouterPlugin#get_plugin_type`
* ExtensionManager loads extensions (default: neutron/extension)
* Extension(ExtensionDesriptor) got method `get_resource` which will return a collection of object having both controller and plugin etc.
* l3 agent service callbacks are registerd at `neutron.services.l3_router.l3_router_plugin.L3RouterPlugin#__init__`.
* fip port is created here `neutron.agent.l3.dvr_fip_ns.FipNamespace#_create_gateway_port`, `dvr_fip_ns.py` implements specific fip namespace.
* router updated notification is received & responsed `neutron.agent.l3.agent.L3NATAgent#_process_router_update`.
* process router with `neutron.agent.l3.agent.L3NATAgent#_process_router_if_compatible` if it does not exist or `self.router_info` is not intialized
* For south-north traffic, traffic originated from VM will first be sent to **local router**, and then go all the way to **snat namespace**; the reply packet will first hit **snat**, then dvr router on **network node**, and finally return to VM. So basically packet will go throught different path which could be easily verified by `tcpdump`.

### RANDOM RANTS

* My question is why `fip` namespace is necessary? Isn't better to still associate floating ip inside each router?