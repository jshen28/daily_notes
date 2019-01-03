# GET PORTS BY SECURITY GROUP

## BACKGROUND

Recently, I am trapped of problem where openstack server takes an unexpected amount of time to spin up. Initial guess is that flattening image could be expensive and waste a lot of time. But since we use 10G NIC, even if image is large, we still do not need wasting so much time. After reading some code snippets, it finally turns out to be a problem of how neutron uses rpc to get ports when remote group is used. In this notes, I would like to talk about the main cause.

## WORKFLOW

To spin up an instance, nova needs to take care of lot of things - networking, volumes, etc - in mind. And the fact that nova offers different way to create instance really make the whole thing more complex. So to keep it simple, I would like limit my scope only to spin up from image.

After instance is properly scheduled to one compute node, *nova-compute* will first prepare all required resources: *network*, *volumes* and pass those parameters to drivers. In this case, it is a libvirt driver. Driver will take those resources and compile them into a libvirt-accepted guest XML, besides **os-vif** will create some anscillary bridges if necessary (for example, traditionally nova-compute take a hybird approach while requires **os-vif** to create at least linuxbridge/veth/port). After guest XML created, driver will first define a domain. If it suceeds, driver will then create and pause this instnace. Then reason to pause VM is to wait for neutron sets up instance networking (security group, port, dhcp, etc.). After **port** is active, a **network-vif-plugged** event will be emit to dedicated compute node and nova-compute will finally resume VM and update database.

## PROBLEM DESCRIPTION

The problem here is that neutron takes an unexpected amount of time to prepare security group when remote group id is used in rule. The related code snippet is (to keep it simple, detailed implementation is trimmed on purpose)

```python
# neutron.db.securitygroups_rpc_base.SecurityGroupInfoAPIMixin
class SecurityGroupInfoAPIMixin(object):
    """API for retrieving security group info for SG agent code."""

    def security_group_info_for_ports(self, context, ports):
        sg_info = {'devices': ports,
                   'security_groups': {},
                   'sg_member_ips': {}}
        rules_in_db = self._select_rules_for_ports(context, ports)

        for (port_id, rule_in_db) in rules_in_db:
            security_group_id = rule_in_db.get('security_group_id')
            if remote_gid:
                if (remote_gid
                    not in sg_info['devices'][port_id][
                        'security_group_source_groups']):
                    sg_info['devices'][port_id][
                        'security_group_source_groups'].append(remote_gid)
                if remote_gid not in remote_security_group_info:
                    remote_security_group_info[remote_gid] = {}
                if ethertype not in remote_security_group_info[remote_gid]:
                    # this set will be serialized into a list by rpc code
                    remote_security_group_info[remote_gid][ethertype] = set()

            direction = rule_in_db['direction']
            rule_dict = {
                'direction': direction,
                'ethertype': ethertype}

            for key in ('protocol', 'port_range_min', 'port_range_max',
                        'remote_ip_prefix', 'remote_group_id'):
                if rule_in_db.get(key) is not None:
                    if key == 'remote_ip_prefix':
                        direction_ip_prefix = DIRECTION_IP_PREFIX[direction]
                        rule_dict[direction_ip_prefix] = rule_in_db[key]
                        continue
                    rule_dict[key] = rule_in_db[key]
            if security_group_id not in sg_info['security_groups']:
                sg_info['security_groups'][security_group_id] = []
            if rule_dict not in sg_info['security_groups'][security_group_id]:
                sg_info['security_groups'][security_group_id].append(
                    rule_dict)
        # Update the security groups info if they don't have any rules
        sg_ids = self._select_sg_ids_for_ports(context, ports)
        for (sg_id, ) in sg_ids:
            if sg_id not in sg_info['security_groups']:
                sg_info['security_groups'][sg_id] = []

        sg_info['sg_member_ips'] = remote_security_group_info
        # the provider rules do not belong to any security group, so these
        # rules still reside in sg_info['devices'] [port_id]
        self._apply_provider_rule(context, sg_info['devices'])

        return self._get_security_group_member_ips(context, sg_info)


    # get port by filtering through securty group id
    def _select_ips_for_remote_group(self, context, remote_group_ids):
        """
        remote_group_ids: remote security group ids
        """
        if not remote_group_ids:
            return {}
        ips_by_group = {rg: set() for rg in remote_group_ids}

        filters = {'security_group_ids': tuple(remote_group_ids)}

        # rcache is instance of *neutron.agent.resource_cache.RemoteResourceCache*
        for p in self.rcache.get_resources('Port', filters):
            port_ips = [str(addr.ip_address)
                        for addr in p.fixed_ips + p.allowed_address_pairs]
            for sg_id in p.security_group_ids:
                if sg_id in ips_by_group:
                    ips_by_group[sg_id].update(set(port_ips))
        return ips_by_group


# neutron.agent.resource_cache.RemoteResourceCache
class RemoteResourceCache(object):
    """Retrieves and stashes logical resources in their OVO format.

    This is currently only compatible with OVO objects that have an ID.
    """
    def get_resource_by_id(self, rtype, obj_id):
        """Returns None if it doesn't exist."""
        if obj_id in self._deleted_ids_by_type[rtype]:
            return None
        cached_item = self._type_cache(rtype).get(obj_id)
        if cached_item:
            return cached_item
        # try server in case object existed before agent start
        self._flood_cache_for_query(rtype, id=(obj_id, ))
        return self._type_cache(rtype).get(obj_id)

    def _flood_cache_for_query(self, rtype, **filter_kwargs):
        """Load info from server for first query.

        Queries the server if this is the first time a given query for
        rtype has been issued.
        """
        query_ids = self._get_query_ids(rtype, filter_kwargs)
        if query_ids.issubset(self._satisfied_server_queries):
            # we've already asked the server this question so we don't
            # ask directly again because any updates will have been
            # pushed to us
            return
        context = n_ctx.get_admin_context()
        resources = self._puller.bulk_pull(context, rtype,
                                           filter_kwargs=filter_kwargs)
        for resource in resources:
            if self._is_stale(rtype, resource):
                # if the server was slow enough to respond the object may have
                # been updated already and pushed to us in another thread.
                LOG.debug("Ignoring stale update for %s: %s", rtype, resource)
                continue
            self.record_resource_update(context, rtype, resource)
        LOG.debug("%s resources returned for queries %s", len(resources),
                  query_ids)
        self._satisfied_server_queries.update(query_ids)

    def get_resources(self, rtype, filters):
        """Find resources that match key:values in filters dict.

        If the attribute on the object is a list, each value is checked if it
        is in the list.

        The values in the dicionary for a single key are matched in an OR
        fashion.
        """
        self._flood_cache_for_query(rtype, **filters)

        return self.match_resources_with_func(rtype, match)


# neutron.api.rpc.handlers.resources_rpc.ResourcesPullRpcApi
class ResourcesPullRpcApi(object):
    """
    implement client side functionality
    """
    @log_helpers.log_method_call
    def pull(self, context, resource_type, resource_id):
        resource_type_cls = _resource_to_class(resource_type)
        cctxt = self.client.prepare()
        primitive = cctxt.call(context, 'pull',
            resource_type=resource_type,
            version=resource_type_cls.VERSION, resource_id=resource_id)

        if primitive is None:
            raise ResourceNotFound(resource_type=resource_type,
                                   resource_id=resource_id)
        return resource_type_cls.clean_obj_from_primitive(primitive)

    @log_helpers.log_method_call
    def bulk_pull(self, context, resource_type, filter_kwargs=None):
        resource_type_cls = _resource_to_class(resource_type)
        cctxt = self.client.prepare()
        primitives = cctxt.call(context, 'bulk_pull',
            resource_type=resource_type,
            version=resource_type_cls.VERSION, filter_kwargs=filter_kwargs)
        return [resource_type_cls.clean_obj_from_primitive(primitive)
                for primitive in primitives]

# neutron.api.rpc.handlers.resources_rpc.ResourcesPullRpcCallback
class ResourcesPullRpcCallback(object):
    """
    implement server side functionality
    """

    @oslo_messaging.expected_exceptions(rpc_exc.CallbackNotFound)
    def pull(self, context, resource_type, version, resource_id):
        obj = prod_registry.pull(resource_type, resource_id, context=context)
        if obj:
            return obj.obj_to_primitive(target_version=version)

    @oslo_messaging.expected_exceptions(rpc_exc.CallbackNotFound)
    def bulk_pull(self, context, resource_type, version, filter_kwargs=None):
        filter_kwargs = filter_kwargs or {}
        resource_type_cls = _resource_to_class(resource_type)
        # TODO(kevinbenton): add in producer registry so producers can add
        # hooks to mangle these things like they can with 'pull'.
        return [obj.obj_to_primitive(target_version=version)
                for obj in resource_type_cls.get_objects(context, _pager=None,
                                                         **filter_kwargs)]

# neutron.objects.base.NeutronDbObject
@six.add_metaclass(DeclarativeObject)
class NeutronDbObject(NeutronObject):

    @classmethod
    def get_objects(cls, context, _pager=None, validate_filters=True,
                    **kwargs):
        if validate_filters:
            cls.validate_filters(**kwargs)
        with cls.db_context_reader(context):
            db_objs = obj_db_api.get_objects(
                cls, context, _pager=_pager, **cls.modify_fields_to_db(kwargs))
            return [cls._load_object(context, db_obj) for db_obj in db_objs]
```

As one can see, neutron server does not use **security_group_ids** to filter all existing ports. The problem of this is all ports will be processed and this is very expensive. Because to assemble a **Port** object, at least *security group*, *security group rule* and *binding* are also required to be created which consumes at least 3 more DB operations. So a simple sum up will show that at least `n*4` database operations. Because database operation is pretty expensive, then if *n* is large, then time consumption is not neglectible.

## TEST SCRIPT

Run following test and observe how long it takes before returning a list of ports.

```python
#!/usr/bin/env python

import sys
from neutron.api.rpc.handlers import securitygroups_rpc as sg_rpc
from neutron import objects
from neutron.objects.ports import Port
from neutron.api.rpc.callbacks import resources
from neutron.agent import resource_cache
from neutron.common import rpc as n_rpc
from oslo_config import cfg
import logging
from neutron_lib import context as n_ctx


logging.basicConfig(level=logging.DEBUG, handler=logging.StreamHandler(sys.stdout))
cfg.CONF(project="test", default_config_files=['/etc/test/test.conf'])

admin_ctx = n_ctx.get_admin_context()

import time
print time.time()
print Port.get_objects(admin_ctx, security_group_id=('db2526f5-89f5-434d-95cd-5eb734ed30', ))
print time.time()
```

## SOLUTION

* Then simplest solution is update openstack release to **queens** where a overloaded method is introduced to first get a subnet of ports.