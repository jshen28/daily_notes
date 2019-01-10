# PROBLEM REMINDER

> reminder for weird Neutron issues

## DVR RELATED

### SERVER CANNOT ACCESS REMOTE IP

> Servers within one VPC which lives on the same compute node have
> different behaviors. While some of them could access internel
> through snat namespace, others failed. If change default gateway
> from distributed interface to centralized snat, then it works.

It first occurs to me that It may be casued by incomplete flow table rules, but it is not. After I manually change default gateway to **centralized gateway**, virtual machine is magically able to access internet target. I am still investigating this issue and hopefully solve this soon. I try to tracepath packet and it appears packet could be successfully transimitted to DVR. Interestingly, I also tested `cirros` on the same node and it seems normal. I tried to allow another IP pair by enabling `allowed-ip` and it **works**. After capturing packets on `qr-+`, it turns out clearly that packet from the problematic IP is not forwarded.

Ok. I finally figure it out, there is an wrong configured ip-rule table which basically sends packet from `172.31.0.17` to a blackhole.

```console
root@cmp001:~# ip netns exec qrouter-ec006fc8-874a-40ab-834a-7e0fba3b6aee ip rule
0:	from all lookup local 
32766:	from all lookup main 
32767:	from all lookup default 
37303:	from 172.31.0.17 lookup 16 
2887712769:	from 172.31.0.1/20 lookup 2887712769

root@cmp001:~# ip netns exec qrouter-ec006fc8-874a-40ab-834a-7e0fba3b6aee ip r show table 16
default via 169.254.124.195 dev rfp-ec006fc8-8 

root@cmp001:~# ip netns exec qrouter-ec006fc8-874a-40ab-834a-7e0fba3b6aee ip rule del table 16
```

### PMTU DISCOVERY

**PMTU Discovery** is used to dynamically change MTU along each path. As [described here](https://tools.ietf.org/html/rfc1191), each IP packet will set DF (Don't Fragment) flag bit to 1 and along the path, if any router do not accept current MTU, it will drop the packet and returns **ICMP** telling sender lower its current value.

On linux, there is a kernel parameter called **net.ipv4.ip_no_pmtu_disc** which is used to enable this functionality. According to [this](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt) and [this](https://www.frozentux.net/ipsysctl-tutorial/chunkyhtml/variablereference.html), this value is set to **FALSE** by default which means PMTU is enabled by default on linux. It seems [Windows 7](https://allthingsnetworking.wordpress.com/2017/03/23/path-mtu-discovery/) also enables this options by defualt.