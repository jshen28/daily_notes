from keystoneauth1 import adapter, loading
from oslo_config import cfg
from keystoneauth1.loading import session as session_loading
from keystonemiddleware._common import config
from keystonemiddleware.auth_token import list_opts


CONF = cfg.CONF

CONF(project='test', default_config_files=['/etc/nova/nova.conf'])

conf = config.Config("auth_token", "keystone_authtoken", list_opts(), {})

group = conf.get('auth_section') or "keystone_authtoken"

plugin_name = (conf.get('auth_type', group=group)
               or conf.paste_overrides.get('auth_plugin'))

plugin_loader = loading.get_plugin_loader(plugin_name)
plugin_opts = loading.get_auth_plugin_conf_options(plugin_loader)

conf.oslo_conf_obj.register_opts(plugin_opts, group=group)
getter = lambda opt: conf.get(opt.dest, group=group)
auth = plugin_loader.load_from_options_getter(getter)

adap = adapter.Adapter(
    session_loading.Session().load_from_options(),
    auth=auth,
    service_type='identity',
    interface='admin',
    region_name=conf.get('region_name'),
    connect_retries=conf.get('http_request_max_retries'))

print(adap.get_endpoint(version=(3, 0)))