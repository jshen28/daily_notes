# SUMMARIZE RPC USAGE

## NEUTRON

| COMPONENT | USE CASE |
|---|---|
| `neutron-metatdata-agent` | heartbeat; proxy request to 169.254.169.254 |
| `l3 agent` | heartbeat; router create; router add interface; router update/add external gateway; |
| `l2 agent` | heartbeat; port update/delete; security group update |
| `dhcp agent` | heartbeat; network create/delete; subnet create/delete |
| `neutron-server` | api; handle heartbeat |