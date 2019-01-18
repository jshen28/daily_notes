# NEUTRON BUGS

| Bug                                                                                                            | Description                                                                                       |
|----------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| [OVS agent may die during `init`](https://bugs.launchpad.net/neutron/+bug/1534110)                             | Exception during `__init__` may cause **ovs-agent** unresponsive                                  |
| [Restart **ovs-agent** causes temporary network interruption](https://bugs.launchpad.net/neutron/+bug/1569795) | If **L2pop** is enabled, restart ovs-agent will cause network interruption for a while            |
| [1](https://bugs.launchpad.net/neutron/+bug/1574092)                                                           | RPC server (rabbitmq) failure related weird behaviors (resource missing, namespace missing, etc.) |
| [conflict datapath id](https://bugs.launchpad.net/neutron/+bug/1697243) | ovs flow rules are deleted accidentally by ovs-agent |
| [ports does not become ACTIVE during provisioning during mass provisioning](https://bugs.launchpad.net/neutron/+bug/1760047) |  |
| [DVR VIP support](https://bugs.launchpad.net/neutron/+bug/1774459) | |