
# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "sjt"
  tenant_name = "sjt"
  password    = "sjt"
  auth_url    = "https://10.110.25.117:5000/v3"
  region      = "RegionOne"
  endpoint_type   = "public"
  domain_name = "Default"
  insecure    = true
}

variable "image_id" {}
variable "flavor_id" {}
variable "key_pair" {}
variable "ext_network" {
  default = "vlan-156"
}

variable "region" {
  default = "RegionOne"
}

resource "openstack_compute_instance_v2" "my_instance" {
  name      = "my_instance"
  region    = "${var.region}"
  image_id  = "${var.image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair  = "${var.key_pair}"
  force_delete = true
  user_data = <<EOF
  #cloud-config
  users:
    - default
    - name: foo
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: users, admin
      gecos: Foo B. Bar
      lock_passwd: false
      passwd: $1$xyz$X11iz6ox24iPDed6detyU.
      home: /home/foo
      shell: /bin/bash
  apt:
    sources: 
      openstack-queens.list:
        source: "deb http://ubuntu-cloud.archive.canonical.com/ubuntu xenial-updates/queens main"
        keyid: EC4926EA

  package_update: true
  package_upgrade: true
  packages:
    - salt-master
    - python-openstackclient
    - mysql-server
    - mysql-client
    - libapache2-mod-auth-openidc
    - python-dev
    - python-pip
    - python3-pip
    - gcc
    - make
  salt_minion:
    pkg_name: 'salt-minion'
    service_name: 'salt-minion'
    config_dir: '/etc/salt'
    conf:
        master: ${openstack_networking_floatingip_v2.test_fip.address}
  write_files:
    - path: /etc/salt/master.d/master.conf
      content: |
        auto_accept: True
    - path: /root/.pip/pip.conf
      content: |
        [global]
        index-url = https://pypi.douban.com/simple
  runcmd:
    - systemctl restart salt-master
    - systemctl restart salt-minion
  EOF

  network {
    uuid = "75ed2818-25b9-4dfa-8987-7a889dedef85"
    name = "admin-test"
  }
}

resource "openstack_blockstorage_volume_v3" "volume_1" {
  region      = "RegionOne"
  name        = "terraform_volume_1"
  description = "first test volume"
  size        = 10
}

resource "openstack_compute_volume_attach_v2" "va_1" {
  instance_id = "${openstack_compute_instance_v2.my_instance.id}"
  volume_id   = "${openstack_blockstorage_volume_v3.volume_1.id}"
}

resource "openstack_networking_floatingip_v2" "test_fip" {
  description = <<EOF
  create a testing purpose floatingip
  EOF
  pool = "${var.ext_network}"
  region = "${var.region}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.test_fip.address}"
  instance_id = "${openstack_compute_instance_v2.my_instance.id}"
}