# PACKER

## INTRODUCTION

Packer is used to create cumstom user images against different cloud. It accepts a json formatted configuration file. User could also pass in customized values under specific sections to provide enhanced function (probably reason for bothering building one anyway.)

## EXAMPLES

### OPENSTACK EXAMPLE

If environment variable is not available in template, `packer` builder will search through `env` instead so you probably would like to source resource file to provide credentials.

```json
{
  "builders": [
    {
      "type": "openstack",
      "ssh_username": "root",
      "image_name": "ubuntu1404_packer_test_2",
      "source_image": "fd2b7890-9905-43c2-8516-4eecd0684703",
      "flavor": "2C4G10DISK",
      "networks": "c0e4cdce-cbd0-4018-bc63-832775472093"
    }
  ],
  "provisioners": [
      {
        "type": "shell",
        "script": "script.sh"
      }
  ]
}
```