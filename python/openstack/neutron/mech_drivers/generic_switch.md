# GENERIC SWITCH

## BACKGROUND

`network-generic-switch` is neutron mechanisum plugin and used to configure popular physical switches.
For environment without advanced networking devices, it could be used to automate configuration process.

## CONFIGURATION

To enable `network-generic-switch`, 2 steps are required

* enable mechanism driver `generic-switch`, by adding it to `mechanism_drivers`
* configure physical switches

For demonstration, a typical configuration looks like

```ini
# switch-name will be used to distinguish switches
# switch name is shown at the begining of line
[genericswitch:switch-name]
device_type = netmiko_cisco_ios
username = user
password = password
ip = ip
secret= secret
port = 22
```

## USAGE

Normally this driver will not be used unless some conditions are met,

* `local_link_connection` is configured

## BUGS

* At least for version 0.4.1, it seems [this commit](https://github.com/openstack/networking-generic-switch/commit/0f9d7d5405014fc0e214a20ef9a993fca20123ce)
add extra **SAVE_CONFIGURATION** for commiting changes. But at leat until **0.4.1**, the file [looks like this](https://github.com/openstack/networking-generic-switch/blob/0.4.1/networking_generic_switch/devices/netmiko_devices/__init__.py#L139), which obviously will not handle tuple correctly. Besides, at least for **icnt** switches, configuration commands will become effective as soon as commands get correctly executed which means remove `SAVE_CONFIGURATION` completely from *cisco.py* is safe.

## DEMO

### NETMIKO DEMO

```python
#!/usr/bin/env python
from netmiko import ConnectHandler


if __name__ == '__main__':

    connect_info = {
        "device_type": "xxx",
        "username": "xxx",
        "password": "xxx",
        "ip": "xxx",
        "secret": "xxx",
        "port": 22
    }

    vlan = 1

    connection = ConnectHandler(**connect_info)

    # by default enable will use
    connection.enable()

    # configure vlan requires `configure terminal` mode
    print connection.send_config_set(vlan)
```

### INITIATE NETWORK GENERIC SWITCH

```python
#!/usr/bin/env python

from oslo_config import cfg
from networking_generic_switch.devices.netmiko_devices.cisco import CiscoIos
from networking_generic_switch import config
from sys import argv

CONF = cfg.CONF


if __name__ == '__main__':

    CONF(
        project='test-generic-switch',
        default_config_files=argv[1:]
    )

    # retrive all configured device info
    devices = config.get_devices()

    # for demonstration, assume it is a cisco machine
    cisco = CiscoIos(devices[devices.keys()[0]])
```