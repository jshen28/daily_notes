# ERROR LOGS

## NEUTRON OPENVSWITCH AGENT

* **VirtualInterfaceCreateException: Virtual Interface creation failed**: I found this log after a virtual machine did not spin up successfully, it turns to be that ovs agent is busy handling exceptions and cannot setup port. But ironically agent still report heartbeat to neutron server.

## SERCURITY GROUP

* Traditionally, security group is created by using iptables (but currently ovs also supports stateful filter). And it appears that iptables has certain rules and neutron server did not check them carefully which could make ovs agent panic and trun into an abnormal state.
  * `iptables -I ${CHAIN} ${RULENUM} -p gre -m multiport --dports 1:99 -j RETURN` this rule is invalid, since module *multiport* does not support **GRE**. The observation is that neutron ovs agent will fail and restart itself every few seconds and produce abnormal amount of logs (> 1G).