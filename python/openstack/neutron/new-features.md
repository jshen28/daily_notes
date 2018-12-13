# NEUTRON NEW FEATURES & BUG FIXES SINCE PIKE

## PIKE

For a full list of releases notes of pike, see [this](https://docs.openstack.org/releasenotes/neutron/pike.html).

Some interesting changes:

* [DVR could be configured to save public IP](https://docs.openstack.org/neutron/latest/admin/config-service-subnets.html)
* DVR agent now has three modes: *dvr_snat*, *dvr* and *dvr_no_external*. The new mode will only route *east-west* traffic.
* The openvswitch L2 agent now supports bi-directional bandwidth limiting.
* Now port mtu is writable.
* Neutron API now supports conditional update
* The openvswitch mechanism driver now supports hardware offload via SR-IOV, requires: openvswitch 2.8.0 and kernel 4.8
* haproxy replaces neutron-ns-metadata-proxy

## ROCKY

## STEIN
