# CONFIGURE WEBSSO

This guide will summarize steps to integrate websso into Horizon. A detailed step from official document could be found [here](https://docs.openstack.org/keystone/pike/advanced-topics/federation/websso.html).

## CONFIGURE KEYSTONE

## KEYSTONE BACKEND RELATED

### CHANGE CONFIGURATION

Because I have already used `openid` as a authentication method, so to make things clear, I decided to add a new method `oidc` under section `[auth]`.

```ini
[auth]

methods = password,token,openid,oidc
openid = keystone.auth.plugins.mapped.Mapped
oidc = keystone.auth.plugins.mapped.Mapped
```

To make required website pass CSRF valiation, under `[federation]`, put

```ini
[federation]

trusted_dashboard = https://mysite1/auth/websso/
trusted_dashboard = https://mysite2/auth/websso/
```

### ADD IDENTITY PROVIDER & MAPPING & FEDERATION PROTOCOL

Make sure create federation protocol named `oidc` to make keystone regnize this new protocol (or it will fail to pass authentication steps).

```bash
openstack federation protocl create oidc --identity-provider ${MY_PROVIDER} --mapping ${MY_MAPPINNG}
```

### APACHE CONFIGURATION

Configure `mod_auth_openidc` to use this new protocol by modifying horizon's configuration file

```ini
OIDCRedirectURI "https://keystone:5000/v3/auth/OS-FEDERATION/identity_providers/keycloak/protocols/oidc/websso"
OIDCRedirectURI "https://keystone:5000/v3/auth/OS-FEDERATION/websso/oidc"

<LocationMatch /v3/OS-FEDERATION/identity_providers/.*?/protocols/oidc/auth>
  # openid-connect use authorization code (?)
  # so it will redirect user to identity provider if required
  AuthType openid-connect
  Require valid-user
  LogLevel debug
</LocationMatch>
<LocationMatch "/v3/auth/OS-FEDERATION/websso/oidc">
  AuthType openid-connect
  Require valid-user
  LogLevel debug
</LocationMatch>
<LocationMatch "/v3/auth/OS-FEDERATION/identity_providers/.*?/protocols/oidc/websso">
  AuthType openid-connect
  Require valid-user
  LogLevel debug
</LocationMatch>
```

## SETUP HORIZON

> `openstack_auth` should be newer than *3.6.1* to make websso work

Edit `/etc/openstack_dashboard/local_settings.py` and add websso related configurations

```python
# disable all ssl verifications
OPENSTACK_SSL_NO_VERIFY = True

# due to a bug, credentials must be present
# but cange WEBSSO_INITIAL_CHOICE could mitigrate
# the problem
WEBSSO_ENABLED = True
WEBSSO_CHOICES = (
    ("credentials", _("Keystone Credentials")),
    ("myidp_openid", "Inspur Corporation - OpenID Connect")
)
WEBSSO_INITIAL_CHOICE = "myidp_openid"
WEBSSO_IDP_MAPPING = {
      "myidp_openid": ("keycloak", "oidc"),
}
```

## ISSUES

* An older versioned `openstack_auth` might introduce a problem desrbied by [this commit](https://github.com/openstack/django_openstack_auth/commit/04491deed11022c29e24a02e69d750e981a7ac7a), and from `queens` **django-openstack-auth** has been merged into main repo of **horizon**.
* By default, openstack does not offer natural support for single click sign in. User has to at least click `connect` button for one time.