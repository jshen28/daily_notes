# OPERATION TOOLS

## COMMAND LINE TOOLS

```bash
rabbitmqctl list_exchanges -p ${vhost} [name type durable auto_delete policy arguments]
rabbitmqctl list_queues -p ${vhost} [name pid slave_pids synchronised_slave_pids]
rabbitmqctl list_bindings -p ${vhost} [source_name source_kind destination_name destination_kind routing_key]
rabbitmqctl list_policies -p ${vhost}
```

## POLICY PARAMETERS

| Policy Parameter Name   | Explanation                                                 |
|-------------------------|-------------------------------------------------------------|
| ha-mode                 | HA mode                                                     |
| ha-params               | extra params for a specific mode                            |
| ha-sync-mode            | automate synchronization process ?                          |
| x-cancel-on-ha-failover | cancel client consumption if master fails                   |
| ha-promote-on-failure   | controls whether unsynchronised mirror promotion is allowed |
| ha-promote-on-shutdown  | promote slave node if master orderly shutdown ?             |
| ha-sync-batch-size      | perform synchronisation in batches                          |

## REFERENCES

* [Rabbitmq HA Guide](https://www.rabbitmq.com/ha.html)
* [Policy Parameters](https://www.rabbitmq.com/parameters.html#why-policies-exist)
* [rabbitmqctl man page](https://www.rabbitmq.com/rabbitmqctl.8.html)
* [rabbitmq configuration guide](https://docs.pivotal.io/rabbitmq-cf/1-12/policies.html)