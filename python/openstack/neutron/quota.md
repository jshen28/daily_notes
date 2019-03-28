# QUOTA MANAGEMENT IN NEUTRON

## BACKGROUND

There are at least two quota drivers in neutron

* `neutron.db.quota.driver.DbQuotaDriver`
* `neutron.quota.ConfDriver`

The main difference lays in the fact that the second one does not support configure tenant quota
individually, instead it will simple read default values from configuration file. The first one,
enabled by default through loading quota extension, will on the contrary allow admin users to calibrate
the values as their needs.

The limitation is to change default values of a given resource, *neutron-server* has to be rebooted to
make it work. To allow dynamic changing values, either `olso.config` supports a *watch-and-notify* mechanism
or *resource registy* should retrieve values dynamically from a data store, if db driver is intact.

## CODE ANALYSIS

This section will pay particular attention to how it works internally. Codes related to quota management scatters
across different parts of this giant code base which somehow makes it frustrating to understand the big picture.

### RESOURCE REGISTRY

Resource registry is used to store resource classes and some default values (eg. quota). A resource class in neutron
generally is something like *network*, *port*, *router*. Resources, except basic objects like *network*, *port*, *subnet*, will be registered by enabled extensions under **extensions** or **ml2/extensions** folders.

Generally `neutron.quota.resource_registry.register_resource` is used to register resources. This method is used
in mainly two places

* `neutron.pecan_wsgi.startup.initialize_all`: default resource will be registered explicitly
* `neutron.api.v2.resource_helper.build_resource_info`: this method will be used when an extension is dynamically loaded and in the meantime creates a new resource type

### TRACKABLE RESOURCE

Tracked resource is registered at the time ml2 plugin is instanciated, according to `neutron.plugins.ml2.plugin.Ml2Plugin#__init__`.

### QUOTA EXTENSION

Quota extension `neutron.extensions.quotasv2.Quotasv2` enables API backend for dynamically modifying tenant quota values.
The side effects are loading db quota drivers into existing system modules.

### PECAN HOOK

From queens, neutron server completely drops support for [legacy web code base](https://github.com/openstack/neutron/commit/e2ea0b4652a261b948bb2e0b4b3be5f08be98793). As [this piece of code](https://github.com/openstack/neutron/blob/stable/queens/neutron/pecan_wsgi/app.py#L37) shows quota checked is enforced through a pecan hook. A hook from my understand is like a filter in the java web world which will basically intercepts request and process it before passing it to the next stop along the chain.

`make_reservation` is used to both check and save resource usages. It uses a `neutron.quota.QuotaEngine` internally to manage different backend. By default, db driver will be used to handle `make_reservation` calls. As it's shown in [method `get_tenant_quotas`](https://github.com/openstack/neutron/blob/master/neutron/db/quota/driver.py#L55), it will first retrieve quotas from in-memory default values and later override those which are modified saved in table quota.