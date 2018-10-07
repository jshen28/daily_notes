# NEUTRON POLICY WORKFLOW

Neutron has `policy.json` file for controlling api accesses, that's said one can modify this file to provision desired functionalities. Although all policies are checked through `oslo.policy` package, different project has somehow completely different code implementations, e.g. nova and neutron. So instead of writing a note covering all of those projects, it might make much sense to focus on individual project.

## BACKUPGROUND

Neutron has two sets of web apis: legacy and pecan based, wherein the first one will be deprecated in the future release due to the flexibility brought by pecan framework (they claim such transformation will not negatively impacting api efficiencies). So I'd like to first focus on pecan policy implementations first.

## CODE ANALYSIS

In Neutron, **resources** basically include `network`, `port`, `subnet` and so on. Their pluralized terms ,`networks` etc., are called **collection**. Actions are what you do with resources, for example you can create/delete/update network/port/subnet, and they are defined like `create_network`. Below, I would like to copy and paste related code snippet to enhance my point.

Here `RESOURCES` define a default set of resources (network, port and subnet). Other resources are defined in service plugins which should be added manually in configuration files.

```python
# neutron.pecan_wsgi.startup.initialize_all
def initialize_all():
    # ---------
    # skip code
    # ---------
    # At this stage we have a fully populated resource attribute map;
    # build Pecan controllers and routes for all core resources
    plugin = directory.get_plugin()
    for resource, collection in RESOURCES.items():
        new_controller = res_ctrl.CollectionsController(collection, resource,
                                                        plugin=plugin)
        manager.NeutronManager.set_controller_for_resource(
            collection, new_controller)
        manager.NeutronManager.set_plugin_for_resource(collection, plugin)

    pecanized_resources = ext_mgr.get_pecan_resources()
    for pec_res in pecanized_resources:
        manager.NeutronManager.set_controller_for_resource(
            pec_res.collection, pec_res.controller)
        manager.NeutronManager.set_plugin_for_resource(
            pec_res.collection, pec_res.plugin)
```

Another thing to keep in mind is how `_plugin_handlers` is defined. I purposely delete some codes in order to make core more apparent. So it could be determined that `_plugin_handlers` are of dict whose keys are operation(action) and values are `{operation}_{collection}` (let's forget about parent since it is not defined).

```python
# neutron.pecan_wsgi.controllers.utils.NeutronPecanController#__init__
class NeutronPecanController(object):

    LIST = 'list'
    SHOW = 'show'
    CREATE = 'create'
    UPDATE = 'update'
    DELETE = 'delete'

    def __init__(self, collection, resource, plugin=None, resource_info=None,
                 allow_pagination=None, allow_sorting=None,
                 parent_resource=None, member_actions=None,
                 collection_actions=None, item=None, action_status=None):
        # ------
        # skip bunch of code
        # ------
        self._plugin_handlers = {
            self.LIST: 'get%s_%s' % (parent_resource, self.collection),
            self.SHOW: 'get%s_%s' % (parent_resource, self.resource)
        }
        for action in [self.CREATE, self.UPDATE, self.DELETE]:
            self._plugin_handlers[action] = '%s%s_%s' % (
                action, parent_resource, self.resource)
```

Then in pecan, policy enforcment is implemented as a pecan hook (which seems like an filter in JAVA). The code is here `neutron.pecan_wsgi.hooks.policy_enforcement.PolicyHook`. Here controller is associated with resource (network etc.), so this implies that `action` will give you a composition of operation and collection ("{operation}_{collections}") as displayed previously.

```python
class PolicyHook(hooks.PecanHook):
    priority = 140

    def before(self, state):

        # ------
        # skip bunch of code
        # ------

        action = controller.plugin_handlers[
            pecan_constants.ACTION_MAP[state.request.method]]

        state.request.context['original_resources'] = original_resources
        for item in resources_copy:
            try:
                policy.enforce(
                    neutron_context, action, item,
                    pluralized=collection)
            except oslo_policy.PolicyNotAuthorized:
                with excutils.save_and_reraise_exception() as ctxt:
                    # If a tenant is modifying it's own object, it's safe to
                    # return a 403. Otherwise, pretend that it doesn't exist
                    # to avoid giving away information.
                    controller = utils.get_controller(state)
                    s_action = controller.plugin_handlers[controller.SHOW]
                    if not policy.check(neutron_context, s_action, item,
                                        pluralized=collection):
                        ctxt.reraise = False
                msg = _('The resource could not be found.')
                raise webob.exc.HTTPNotFound(msg)
```

The policy is actually enforced in `neutron.policy.enforce`, where `context` is request context, `action` is like `create_networks` etc, `target` describes resource you would like to request, for example its *project_id*, *domain_id* etc (for more information see default `policy.json`)

The core of enforcement is `neutron.policy._build_match_rule`. It looks pretty complex and I am quite get all the detail but nevertheless some apparent takeaway could be got from reading the code below,

```python
def _build_match_rule(action, target, pluralized):
    match_rule = policy.RuleCheck('rule', action)
    resource, enforce_attr_based_check = get_resource_and_action(
        action, pluralized)
    if enforce_attr_based_check:
        # assigning to variable with short name for improving readability
        res_map = attributes.RESOURCE_ATTRIBUTE_MAP
        if resource in res_map:
            for attribute_name in res_map[resource]:
                if _is_attribute_explicitly_set(attribute_name,
                                                res_map[resource],
                                                target, action):
                    attribute = res_map[resource][attribute_name]
                    if 'enforce_policy' in attribute:
                        attr_rule = policy.RuleCheck('rule', '%s:%s' %
                                                     (action, attribute_name))
                        # Build match entries for sub-attributes
                        if _should_validate_sub_attributes(
                                attribute, target[attribute_name]):
                            attr_rule = policy.AndCheck(
                                [attr_rule, _build_subattr_match_rule(
                                    attribute_name, attribute,
                                    action, target)])
                        match_rule = policy.AndCheck([match_rule, attr_rule])
    return match_rule
```

Recall that rules are defined in policy.json, here `match_rule` actually associates with a specific entry. Aslo keep in mind that policy also checks if user has privilege accessing certian attributes, which is achieved by those `AndCheck`.

## OSLO.POLICY

`oslo.policy` does the amazing jobs of validating user requests.

### RULES (CHECKS)

Rules could be catagorized into three classes in `oslo.policy`: extension, registered checks and None check, where None could be thought as a default checker.

Extension rules are defined and loaded from namespace `oslo.policy.rule_checks`, of course one can define rules on their own but the current implementation is http(s) checks which enables validating request by http(s) requests.

Registered check and None check are registerd by python decorator `@register()`, right now there are three rules `rule`, `role` and `None` where the latter stands for a generic check.