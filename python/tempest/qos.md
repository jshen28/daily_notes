# QoS

## API

Openstack offers a set of [APIs](https://developer.openstack.org/api-ref/network/v2/index.html#quality-of-service) to handle QoS related requests. It seems that Tempest smoke has not yet contained tests on these features, so it might be good to implement it oneself. The related APIs are also listed there so you can call these when extension is enabled.