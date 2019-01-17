# UPDATE MTU

Update MTU is relatively simple, executing `openstack set network ${NET_ID} --mtu ${NEW_VALUE}` is enough. But of course make sure you have the correct version, and if openstack client command line tool does not provide support, then one has no choice but turn to manually invoking rest apis.

The real problem is **how long it will take** before guest OS saw those correct values without any human intervention (for example restart network inside guest VM) and whether modification will **be harmful** to cluster. To test it, I have to manually spin up virtual machine and try to modify the existing network.

Per described [here](https://www.serverbrain.org/network-services-2003/how-the-dhcp-lease-renewal-process-works-1.html), dhcp client will try to **release its IP address for a period of half of its full lease time**, for example if lease time is 10min, then client will release it every 5 min, this behavior is observed by watching syslog. Interestingly even if release failed it will **not lead to IP deprivation of existing IP** as long as it's still in the valid lease time.

Another interesting question to ask is how long it takes dhclient to refresh its parameters which passed along DHCP response, according to [this post](https://serverfault.com/questions/418898/force-the-dhcp-server-to-renew-the-ip-address-of-a-client-machine-without-doing/418905#418905) the result is quite disapointing: it might never change it until you restart the corresponding network interface card, but I still need to investigate. I tried to dump dhcp packets and found new mtu value is given backup but dhclient does not adopt it.

Another problem is even if you reboot VM to change its MTU, those **tap** devices will never change because it does not listen to events related to neutron network changing. But it may not be as bad as the one mentioned above. Ubuntu has issues above while it works on centos 7.4. And there is inter-vpc connection problem between windows 2012 DC and centos.