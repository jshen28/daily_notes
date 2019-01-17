# BUILD HORIZON FROM SOURCE

> Build Horizon from source is tedious and
> anyone takes this challenge should be patient
> to solve unexpected problems

## PREPARATIONS

> Be extemely careful with the steps and download source code from release
> rather than git repo.

* Firstly, a quite detailed steps are listed in an official [documentation](https://docs.openstack.org/horizon/latest/install/from-source.html#static-assets).
* Next, download required Horizon edition from [official release note](https://releases.openstack.org/pike/index.html#pike-horizon), different microversion might add some extra functionalities but should not have big changes.
* Install `gettext` is required by `i18n` later
* Lastly, install `apache2`, `libapache2-mod-wsgi` I use the default version (2.4.18) shipped with official repo.

With extra efford, it is also possible to build and run project inside a virtualenv, as usual, to create a virtualenv on ubuntu one can do `sudo apt install -y python-pip python-virtualenv`.

## BUILD

Building process is rather simple, follow official documentation is mostly safe.

> Be careful, do not run following script with **root** user

```bash
ENV_NAME=horizon
virtualenv ${ENV_NAME}
source ${ENV_NAME}/bin/activate

wget ${RELEASE_URL} -O ${NEV_NAME}/share/horizon.tar.gz
tar xzf ${ENV_NAME}/share/horizon.tar.gz

# BE CAREFUL, THIS STEP IS NOT RIGHT
cd ${ENV_NAME}/share/horizon/

pip install -r requirements.txt
./manage collectstatic --yes
./manage compress --force

cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py
```

After above process, javascrpit should be correctly generated, look inside `${ENV_NAME}/share/horizon/static/dashboard/js` to make sure they are there. Then next step is to modify local settings.

> directly edit `local_settings.py` inside lib folder may not be best
> practice

Because `local_settings.py` is rather long (more than 800 lines), for simplicity I will just put my modified version here

```python
OPENSTACK_SSL_NO_VERIFY = True

WEBSSO_ENABLED = True

WEBSSO_CHOICES = (
    ("credentials", _("Keystone Credentials")),
    ("myidp_openid", "Inspur Corporation - OpenID Connect")
)
WEBSSO_IDP_MAPPING = {
      "myidp_openid": ("keycloak", "oidc"),
}
WEBSSO_INITIAL_CHOICE = "myidp_openid"

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'memcache:11211'
    }
}
```

## CONFIGURE APACHE2

> Make sure project is not built by root user
> and put elsewhere rather
> than **/root** to avoid permission related issues

* generate configuration by hit `./manage.py make_web_conf --apache > /etc/apache2/sites-available/horizon.conf`
  * following modification may be required
    * In `WSGIScriptAlias`, change wsgi file name to **django.wsgi**
    * add correct user & group pair (eg. `user=ubuntu group=ubuntu`) to `WSGIDaemonProcess`
* **Disable** default site by `a2dissite 000-default`
* **Enable** horizon by `a2ensite horizon`
* Reload & restart service `systemctl reload apache2 & systemctl restart apache2`

## CUSTOMIZATION

In case customization is required, make sure repeat `manage.py collectstatic` and `manage.py compress` to update javascript and html changes. Restart apache2, if python code is updated to enable new features.

## PROBLEMS

* Horizon always seek to use **adminURL**, according to `openstack_dashboard.context_processors.openstack`, it seems that if user is project admin, horizon will automatically adopt admin endpoint which is rather annoying
* Page constantly jumps back to login page even if logging has succeeded.

## FURTHER READING & REFERENCES

* [Configure websso](https://docs.openstack.org/keystone/pike/advanced-topics/federation/websso.html)
* [Configure openid connect](https://docs.openstack.org/keystone/pike/advanced-topics/federation/openidc.html)
* [mod_wsgi official documentation](https://modwsgi.readthedocs.io/en/develop/index.html)
* [use virtualenv with mod_wsgi](https://www.digitalocean.com/community/tutorials/how-to-run-django-with-mod_wsgi-and-apache-with-a-virtualenv-python-environment-on-a-debian-vps)