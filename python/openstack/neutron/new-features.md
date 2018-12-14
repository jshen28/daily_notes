# NEUTRON NEW FEATURES & BUG FIXES SINCE PIKE

## OVERVIEW

### PIKE

For a full list of releases notes of pike, see [this](https://docs.openstack.org/releasenotes/neutron/pike.html).

Some interesting changes:

* On DVR
  * [Use service-type to save public IP](https://docs.openstack.org/neutron/latest/admin/config-service-subnets.html)
  * DVR agent now has three modes: *dvr_snat*, *dvr* and *dvr_no_external*. The new mode will only route **east-west** traffic.
* Neutron API updated
  * Now port mtu is writable.
  * haproxy replaces neutron-ns-metadata-proxy
  * Neutron API now supports conditional update
* OVS agent
  * The openvswitch mechanism driver now supports hardware offload via SR-IOV, requires: openvswitch 2.8.0 and kernel 4.8
  * The openvswitch L2 agent now supports bi-directional bandwidth limiting.
* Bug fix
  * For InfiniBand(IB), dhcp requires dhcp option to be a number

### ROCKY

* New Feature
  * **Multiple port bindings** [are added](https://docs.openstack.org/releasenotes/neutron/rocky.html#new-features). You can have multiple bindings for compute owned port, but only one of them could be active. This support is added particularly to help migrate instance.
  * **Port Forwarding** for floating ip has been added, but it has some problems when creating port forwarding with different protocols. (The issue has been resolved under stein)
  * Add support for modifying **segment_id** for an existing subnet and [thus make it possible to change it to a routed network](https://docs.openstack.org/releasenotes/neutron/rocky.html#new-features) (?)
  * Add support for filtering port by security group if *port-security-group-filtering* is enabled
  * Add support for filtering by empty string if *shim* extension is loaded.
* Issue
  * [In the case when the number of ports to clean up in a single bridge is larger than about 10000, it might require an increase in the ovsdb_timeout config option to some value higher than 600 seconds.](https://docs.openstack.org/releasenotes/neutron/rocky.html#known-issues)
* Bug Fix
  * [HA router remains active even all network nodes are down](https://bugs.launchpad.net/neutron/+bug/1682145). This has been fixed and if such situation happens, router status will degraded to **standby**
  * [Conntrack might take a long time to clean up on large deployment](https://bugs.launchpad.net/neutron/+bug/1745468)
