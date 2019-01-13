# LINUX CAPABILITIES & ACLS

## LINUX PROCESS CAPABILITIES

Linux uses process capabilities to fine grain control of individual user's capabilities. Linux fined graiend capabilities is particularly useful for granting privileges to unprevileged processes, because of course privileged processes will bypass any security restrictions by default (but you can still change it to anything you want).

The background for learning capabilities is I am trapped by an annoying **permission denied** exception complained by **oslo.privsep** which is a sub project used for privilege separation in OpenStack. After some debugging, it turns out if I comment out `capabilitities.drop_all_caps_except` or permit execution on a folder for users, the error will go away. And what `drop_all_caps_except` is trying to do is simple: drop extra capabilities on the current process.

### PRINT PROCESS CAPABILITIES

In short, to print capabilities for current process, on could execute

```console
root@cmp:~# capsh --print
Current: = cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,37+ep
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,37
Securebits: 00/0x0/1'b0
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
uid=0(root)
gid=0(root)
groups=0(root)

sjt@cmp:~$ capsh --print
Current: =
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,37
Securebits: 00/0x0/1'b0
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
uid=1000(sjt)
gid=1000(sjt)
groups=4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),113(lpadmin),128(sambashare),999(docker),1000(sjt),1001(tomcat)
```

`capsh` prints capabilities for current shell console session, to get process capabilities on other pid, you can execute `getpcaps`,

```console
sjt@cmp:~$ getpcaps 5
Capabilities for `5': = cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,37+ep
```

Here the trailing **+ep** means capabilities are effecitive and permitted. There are **three** categories of capabilities: **effective**, **permitted** and **inherited**. **Effective** means such capabilities are enabled; **Permitted** means caps process should legally use and **inherited** means caps which are kept from parent proceses. One can find a nice explanation [here](https://www.insecure.ws/linux/getcap_setcap.html#id1). To get a list of all caps and their meanings read [source code](https://elixir.bootlin.com/linux/latest/source/include/uapi/linux/capability.h).

## RERERENCES

* [Step by step tutorial for displaying and changing cap](https://linux-audit.com/linux-capabilities-101/)
* [caps definitions](https://elixir.bootlin.com/linux/latest/source/include/uapi/linux/capability.h)
