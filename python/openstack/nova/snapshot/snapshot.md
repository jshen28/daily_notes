# OPENSTACK SNAPSHOT

Openstack will handle instance snapshot differently depending on what backend is used, volume or image backend. Basically volume backed virtual machine will have their machine image in `volumes` pool while image backed virtual machines will have theirs in `vms` pools impllying that you cannot reuse them after termination.

## INSTANCE SNAPSHOT

### OVERVIEW

Depending on which **backend** you choose, you have different implementations of snapshot interfaces. And the typical backends are listed in the code:

```python
self.BACKEND = {
    'raw': Flat,
    'flat': Flat,
    'qcow2': Qcow2,
    'lvm': Lvm,
    'rbd': Rbd,
    'ploop': Ploop,
    'default': Qcow2 if use_cow else Flat
}
```

With a typical openstack cluster setup out there with ceph as default software storage provider, the backend is `rbd`. But by design, nova will allow user to have heterogeneous backends co-exist in the system. And of course, it also dependes on kvm+libivrt is used for virtualization & vm management.

Snapshot logic is implemented at `nova.virt.libvirt.driver.LibvirtDriver#snapshot`. It needs to figure out where the image is, what is the type, where to put it, update task status, etc. Noticing that image-type `rbd` will be translated into `raw` because it is how the image is saved. Depending on configuration and instance state, code will determine if live snapshot is made. The related configurations are,

* `CONF.ephemeral_storage_encryption.enabled`
* `CONF.workarounds.disable_libvirt_livesnapshot`
* image is not lvm backend

By default the second configuration is disabled by default, so it will always be a cold snapshot. 

Code will try to make a **direct snapshot** at first, which is basically clone & flatten machine image from `vms` pool to `images` pool, but remember that ceph user `client.nova` should be given enough privilege to write to targeted pools, or you'll have

> Performing standard snapshot because direct snapshot failed: no write permission on storage pool images: Forbidden: no write permission on storage pool image

```python
# try to make snapshot & return its location
metadata['location'] = root_disk.direct_snapshot(context, snapshot_name, image_format, image_id, instance.image_ref)
self._snapshot_domain(context, live_snapshot, virt_dom, state, instance)

# will update glance metadata
self._image_api.update(context, image_id, metadata, purge_props=False)
```

Interesting enough what makes it fast is that uploading to glance store is avoided by simply recording image's metadata information.

Of course give two much permission to ceph user could have potential secrity risk and openstack admins sometimes are not willing to experience that. So in case of *direct snapshot* fails, you still could snapshot the instance but with a more tedious steps.

```python
snapshot_directory = CONF.libvirt.snapshots_directory
fileutils.ensure_tree(snapshot_directory)
with utils.tempdir(dir=snapshot_directory) as tmpdir:
    try:
        out_path = os.path.join(tmpdir, snapshot_name)
        if live_snapshot:
            # NOTE(xqueralt): libvirt needs o+x in the tempdir
            os.chmod(tmpdir, 0o701)
            self._live_snapshot(context, instance, guest,
                                disk_path, out_path, source_format,
                                image_format, instance.image_meta)
        else:
            root_disk.snapshot_extract(out_path, image_format)
    finally:
        self._snapshot_domain(context, live_snapshot, virt_dom,
                              state, instance)
        LOG.info("Snapshot extracted, beginning image upload", instance=instance)

    # Upload that image to the image service
    update_task_state(task_state=task_states.IMAGE_UPLOADING,
            expected_state=task_states.IMAGE_PENDING_UPLOAD)
    with libvirt_utils.file_open(out_path, 'rb') as image_file:
        self._image_api.update(context, image_id, metadata, image_file)
```

Because cold snapshot is taken, `snapshot_extract` function is invoked which basically is first executing `qemu-img convert`, then upload image to glance store by `glance client`. This is less inefficient that direct snapshot because traffic flow will need to bypass `ctl` node using control network before taking their way to the ceph cluster.

### DIRECT SNAPSHOT

Direct snapshot with rbd as backend will require `nova` have **rwx** permission for **images** pool. A typical step for creating a direct snapshot involves,

1. Find out parent pool name, using `RBDDriver.parent_info` (I do not know corresponding rbd command, but at least you can use `rbd ls -l` or `rbd info` to get parent info), parent information could be retrived from a clone. But the problem is that image could be flattend so parent info is erased, then nova will try to get poll name directly from glance store.
2. Create snapshot, clone image from `vms` (by configuration **CONF.libvirt.images_rbd_pool**) to `images`

Code snippet is,

```python
self.driver.create_snap(self.rbd_name, snapshot_name, protect=True)
location = {'url': 'rbd://%(fsid)s/%(pool)s/%(image)s/%(snap)s' %
                    dict(fsid=fsid,
                        pool=self.pool,
                        image=self.rbd_name,
                        snap=snapshot_name)}
self.driver.clone(location, image_id, dest_pool=parent_pool)
# Flatten the image, which detaches it from the source snapshot
self.driver.flatten(image_id, pool=parent_pool)
```

### INDIRECT WAY

If above method fails, for example user *clinet.nova* does not have write permission or different ceph clusters are used for images and vms, then another workaround step will be taken to assume the task.

1. Extract snapshot, effectively copying all the contents into a temp folder using `qemu-img`.
2. Upload image to glance store.

```python
def _convert_image(source, dest, in_format, out_format, run_as_root):
    # NOTE(mdbooth): qemu-img convert defaults to cache=unsafe, which means
    # that data is not synced to disk at completion. We explicitly use
    # cache=none here to (1) ensure that we don't interfere with other
    # applications using the host's io cache, and (2) ensure that the data is
    # on persistent storage when the command exits. Without (2), a host crash
    # may leave a corrupt image in the image cache, which Nova cannot recover
    # automatically.
    cmd = ('qemu-img', 'convert', '-t', 'none', '-O', out_format)
    if in_format is not None:
        cmd = cmd + ('-f', in_format)
    cmd = cmd + (source, dest)
    try:
        utils.execute(*cmd, run_as_root=run_as_root)
    except processutils.ProcessExecutionError as exp:
        msg = (_("Unable to convert image to %(format)s: %(exp)s") %
               {'format': out_format, 'exp': exp})
        raise exception.ImageUnacceptable(image_id=source, reason=msg)
```

```python
with libvirt_utils.file_open(out_path, 'rb') as image_file:
    self._image_api.update(context, image_id, metadata, image_file)
```

## VOLUME SNAPSHOT
