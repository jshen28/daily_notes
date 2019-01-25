# CLOUD-INIT INTRODUCTION

`cloud-init` is used for automatically initializing system. User could use `cloud-init` configuration files in `yaml` to make agent do the work for you.

This demo set is mainly used to illustrate some useful modules.

## CREATE USERS

To create a new user and not override existing ones, one could

```yaml
#cloud-config
users:
  - default
  - name: test
    groups: users, admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    # to generate a salted password: https://unix.stackexchange.com/questions/81240/manually-generate-password-for-etc-shadow
    # openssl passwd -1 -salt ${SALT} ${PASSPHRASE}
    passwd: $1$xyz$X11iz6ox24iPDed6detyU. # 123456
```

## INSTALL PACKAGES

### UBUNTU

```yaml
#cloud-config
package_upgradable: true
packages:
  - salt-master
  - salt-minion
```

## WRITE FILES

```yaml
#cloud-config
write_files:
  - path: /foo/bar
    permission: 0600
    owner: ubuntu:ubuntu
    content: |
      a
      b
```
