# NEUTRON BUGS

## BUGS

| Bug                                                                                                            | Description                                                                                       |
|----------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| [OVS agent may die during `init`](https://bugs.launchpad.net/neutron/+bug/1534110)                             | Exception during `__init__` may cause **ovs-agent** unresponsive                                  |
| [Restart **ovs-agent** causes temporary network interruption](https://bugs.launchpad.net/neutron/+bug/1569795) | If **L2pop** is enabled, restart ovs-agent will cause network interruption for a while            |
| [RPC failure introduced problems](https://bugs.launchpad.net/neutron/+bug/1574092)                                                           | RPC server (rabbitmq) failure related weird behaviors (resource missing, namespace missing, etc.) |
| [conflict datapath id](https://bugs.launchpad.net/neutron/+bug/1697243) | ovs flow rules are deleted accidentally by ovs-agent |
| [ports does not become ACTIVE during provisioning during mass provisioning](https://bugs.launchpad.net/neutron/+bug/1760047) | Neutron seems to have a lot of concurrent issues  |
| [DVR VIP support](https://bugs.launchpad.net/neutron/+bug/1774459) | DVR router cannot get MAC for VIP address |
| [PMTU Disc failed with DVR mode](https://bugs.launchpad.net/neutron/+bug/1799124) | I do not fully understand the problem ... |
| [tso enabled nic may hit performance issues](https://bugs.launchpad.net/neutron/+bug/1551179) | enable offloading support may bring unexpected performance issue |
| [dhcp lease file is not updated correctly](https://bugs.launchpad.net/neutron/+bug/1783908) | Sometimes, VM failed obtain fixed IP due to binding is not changed |
| [ovs-agent does not properly clean up flow rules sometimes](https://bugs.launchpad.net/neutron/+bug/1808541) | Events process order matters |

## FEATURES

| Blue Prints | Description |
|---|---|
