# ANYLYZE & INVESTIGATE FLOWS

## COMMON COMMANDS

| Command Name                                            | Description                                                   |
|---------------------------------------------------------|---------------------------------------------------------------|
| `ovs-vsctl show`                                        | show detailed information for ports/interfaces on each bridge |
| `ovs-vsctl list/get interface/port`                     | get/list interface/ports porperties                           |
| `ovs-vsctl add-port ${BRIDGE} ${PORT}`                  | add ovs port to a bridge                                      |
| `ovs-vsctl set port/interface ${NAME} ${OPTIONS}`       | change port/interface attributes                              |
| `ovs-ofctl show ${BRIDGE}`                              | show bridge detail                                            |
| `ovs-ofctl dump-flows ${BRIDGE} [option1,options2,...]` | dumping flow rules on a given bridge                          |
| `ovs-appctl ofproto/trace ${BRIDGE} [packet detail]`    | debug packet flow on a given bridge                           |
| `ovs-appctl fdb/show ${BRIDGE}`                         | dump switch cache on a given bridge                           |

## TRACING & TROUBLESHOOTING

Troubleshoot flow rules. Recently I am experiencing a great deal of unexpected *ovs flow rule* related problems. Sometimes virtual machines lost their ips or dhcp request cannot be broadcasted to proper nodes; other times, VM on different hypervisor inside same VPC couldn't reach out to each other. To quickly locate & solve problem, some basic tools would be very welcomed, so I am going to keep a note of what I have found useful to trace & solve most problems related to L2 layer.

### TRACING WITH OFPROTO/TRACE

OpenVswitch is a nice tool to build a software defined vswitch, it is flexible and performant. The only complaint from me is that its documentation is extremely hard to get for me if I do not have any background information, so sometimes I am really frustrated: tracing is among these situations.

Because of the complexity of openflow rules, openvswitch offers built-in tracing tools to help debug existing rules. It is powerful enough to debug a wide range of different protocols: **arp**, **icmp**, **tcp**, **udp**. It is good to have those features but it is hard to find guides. So I would like to record gathered information here for future reference. Of course, this guide will be continuously repolished along the way.

To debug flow table, `ovs-appctl ofproto/trace` is used most of the times.