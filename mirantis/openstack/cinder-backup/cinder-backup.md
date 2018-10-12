# CONFIGURE CINDER-BACUP SERVICE

In production, we are asking for using openstack cinder-backup to offer volume backup and restoration. Initially, this is not incorporated into MCP500 reclass model. But it turns out to be amazingly easy to set up environment and make things work.

In this note, I will review configurations and commands used during deploying as well as some useful references.

## CONFIGURE CEPH AS BACKEND

Cinder-backup service could take ceph rbd as its back end. Mirantis has already made cinder-backup service as part of their reclass offering. So what needs to be done is quite trivial.

### FIRGURE OUT INSTALLATION LOCATION

First, one needs to figure out where you want to put your application. The typical situation is that cinder-backup service colocates with openstack control plane services, but of course you can have it on a separate node in order to mitigate your networking traffic. In the following, I would like to specifically talk about put your it on your control node.

### MODIIFY RECLASS FILE

Modify reclass file is amazingly easy compared with adding other components, you simply need to add following lines in `openstack/control.yaml` file.

```yaml
---
parameters:
  cinder:
    controller:
      backup:
        engine: ceph
        ceph_user: cinder
        ceph_pool: backup
```

In the above configuration, we need to define backup engine as ceph as well as fills in designed ceph users & pools. Keep in mind that ceph user should have proper privileges for given rbd pool.

### VALIDATE & RUN SALT STATE

Run the following command on `cfg01*` to install service.

```bash
salt 'ctl*' saltutil.refrehs_pillar
salt 'ctl*' saltutil.syn_call

# '-b' makes salt executes states in a batch mode
# which is you can tell it how many minions could
# run the command simultaneously.
salt 'ctl*' state.sls cinder.controller -b1
```

## CONFIGURE SWIFT AS BACKEND

Salt formular does not support swift as cinder-backup's backend, which forces me to write a configuration file myself. This is pretty straight forward, you just need to write down your typical configuration and in order to make it general, put some jinja2 variables anywhere it may change for another environment.

Still this document only covers the situation where cinder-backup lives with all the other **openstack control plance services**.

### ADD NEW CONFIGURATION

In order to use swift as backend, first write a configuration file which should be later put under `cinder/files/backup_backend` folder, then contents look like following and file name should be `_swift.conf` depending on how you call it in reclass file.

```ini

# swift backupend
backup_driver = cinder.backup.drivers.swift
backup_swift_url = {{ controller.backup.backup_swift_url }}
{%- if controller.backup.swift_auth_url is defined %}
backup_swift_auth_url = {{ controller.backup.swift_auth_url }}
{%- endif %}
{%- if controller.backup.swift_project_domain is defined %}
backup_swift_project_domain = {{ controller.backup.swift_project_domain }}
{%- endif %}
{%- if controller.backup.swift_project is defined %}
backup_swift_project = {{ controller.backup.swift_project }}
{%- endif %}
backup_swift_auth = {{ controller.backup.get('swift_auth', 'per_user') }}
backup_swift_auth_version = {{ controller.backup.get('auth_version', 3) }}
{%- if controller.backup.swift_user is defined %}
backup_swift_user = {{ controller.backup.swift_user }}
{%- endif %}
{%- if controller.backup.swift_user_password is defined %}
backup_swift_key = {{ controller.backup.swift_user_password }}
{%- endif %}
backup_swift_container = {{ controller.backup.get('backup_swift_container', 'volumebackup') }}
backup_swift_object_size = {{ controller.backup.get('object_size', 52428800) }}
backup_swift_retry_attempts = {{ controller.backup.get('retry_attempts', 3) }}
backup_swift_retry_backoff = {{ controller.backup.get('retry_backoff', 2) }}
backup_compression_algorithm = {{ controller.backup.get('compression_algorithm', 'zlib') }}
backup_swift_auth_insecure = True
```

### MODIFY CONFIGURATION FILE

Notice that value `swift` will be mapped to `_swift.conf` which has been added above. Maintainer could easily calibrate values listed above and put it in the configuration file if she wants to change some values.

```yaml
  cinder:
    controller:
      backup:
        engine: swift
        backup_swift_url: ${SWIFT_URL}
        backup_swift_container: volumebackup
```

### CONFIGURATION PARAMETER EXPLAINED

Configuration of swift backed cinder-backup has two flavors: on one hand you may configure it to use project for each log-in user or you can configure it use a system-wide user. The related configuration option is called **backup_swift_auth** and its value is either *per_user* or *single_user*.

Another important options are **backup_swift_object_size** and **backup_swift_block_size**. Notice that rbd file will be compressed, truancated and then put into swift backend. The **backup_swift_object_size** defines the size of object being saved; **backup_swift_block_size** is the block tracked by cinder-backup service which enables incremental backup capability.

## POTENTIAL BUGS

### CINDER-VOLUME LOGGING CONFIGURATION MISSING

While observing system state on Kibana, it occurs to me that `cinder-volume` logs are missing. The problem seems to reside on the fact that fluentd configuration for `cinder-volume` is missing. This bug is pretty easy to verify: simply log into kibana dashboard and search for it, you will not find it under colume *programname*.

The reason of this problem is salt formula does not handle correctly if `cinder-volume` lives with `cinder-api`. Related code snippet is,

```yaml
{%- if not pillar.cinder.get('controller', {}).get('enabled', False) %}
# skip code block #

{%- if volume.logging.log_handlers.get('fluentd', {}).get('enabled', False) %}
cinder_volume_fluentd_logger_package:
  pkg.installed:
    - name: python-fluent-logger
{%- endif %}

{% for service_name in cinder_log_services %}
{{ service_name }}_logging_conf:
  file.managed:
    - name: /etc/cinder/logging/logging-{{ service_name }}.conf
    - source: salt://cinder/files/logging.conf
# skip code block #
{%- endif %}
```

As you can see if **controller** is enabled on the node, then all above code block will be ignored which is incorrect because `cinder-volume` requires a logging configuration for itself which should be called **logging-cinder-volume.conf**.