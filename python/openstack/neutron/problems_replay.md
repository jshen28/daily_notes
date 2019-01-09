# PROBLEM REMINDER

> reminder for weird Neutron issues

## DVR RELATED

### SERVER CANNOT ACCESS REMOTE IP

> Servers within one VPC which lives on the same compute node have
> different behaviors. While some of them could access internel
> through snat namespace, others failed.

It possibly has something to do with incomplete flow table. `ip neigh` shows that mac address is correct but `arping` cannot get response. It is quite confusing because it seems that `ping` will use cache value if destination address lives in the same subnet as the machine, but will try to fetch mac address when forward packet to a gateway.

### PMTU DISCOVERY

**PMTU Discovery** is used to dynamically change MTU along each path. As [described here](https://tools.ietf.org/html/rfc1191), each IP packet will set DF (Don't Fragment) flag bit to 1 and along the path, if any router do not accept current MTU, it will drop the packet and returns **ICMP** telling sender lower its current value.

On linux, there is a kernel parameter called **net.ipv4.ip_no_pmtu_disc** which is used to enable this functionality. According to [this](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt) and [this](https://www.frozentux.net/ipsysctl-tutorial/chunkyhtml/variablereference.html), this value is set to **FALSE** by default which means PMTU is enabled by default on linux. It seems [Windows 7](https://allthingsnetworking.wordpress.com/2017/03/23/path-mtu-discovery/) also enables this options by defualt.