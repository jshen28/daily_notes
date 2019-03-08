
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
  name      = "sjt_test_master"
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
  package_update: true
  package_upgrade: true
  packages:
    - wget
    - curl
    - apt-transport-https
    - gnupg-agent
    - software-properties-common
  runcmd:
    - echo $(date) > /var/log/timestamp
    - chown -R ubuntu:ubuntu /home/ubuntu
    - chmod 600 /home/ubuntu/.ssh/id_rsa
    - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    - sudo apt update
    - sudo apt install docker-ce
  write_files:
    - path: /home/ubuntu/.ssh/id_rsa
      permission: 0600
      owner: ubuntu:ubuntu
      content: |
        -----BEGIN RSA PRIVATE KEY-----
        Proc-Type: 4,ENCRYPTED
        DEK-Info: DES-EDE3-CBC,24180A8361C80084

        j+rUb2zWZcCCf/z6mlXnO8flfwIen9lQG5jvDaH4ttZssLH+KcwhunsfIC+mA+Hi
        JLW4YWch3f4fYjx4m3NMRwdm1iTX3rL98Ut2gT6USmIa0Ip1qwXC2sGuRPN6ltyN
        Kgnsw8v4gRUO2fU/8WiAvUOAmCGXwWhpcbmKcU0OI8BB96wduictNJ4Yggu/Sn2q
        2np54LxeLusWXyxj0x6u72c4lVqgwbJFbf8hnoAtYp6CSvfXZhNag4aBxwO1zoD+
        Xzuf2QEa3SrJlspxsNSWhu1WBEtOwyviGblq0wEVAu2EsApSEJXwfh6gVs96zphF
        UVM3jLheUo1jIbzyu5EuINOsuFzVhUTuqb2D3YIxB4L3V7seTVjUMft1l0Ytxqpb
        /nI5PT+x5oEL9TykNc8XSVZCFBPnnEfCmXtTatuj91/+/AYaRPhtRDsKxVYOmoid
        f/xsAMPEZMJu5f/rBpldY52t6Kw+/1o6QbX/XgFoDQDlWG5zq56XRJMh59Z4YWQr
        sxDNxyuhXLVcI5m6/5ieGs9IpUsBLW8hHBi6oqBrJ9pTuUazep1/n7NdxuIdmaIk
        vXqFPu7pVNYuvBHo56MXoVSN8xEK4vktmgBxdP+q5q0D+SWhNXI6+WAa7pkKf87T
        AqIQdzLCcWEMlKLV4Pa7Tx2hGay25JRT/jTOtrfjtUkV1EGoP6McZ8ht2X4EpuVV
        nxltPNu6rKXCAFByMU1ATW06dbjpa+9FFPUvsh9nMvCJs2q3cPHxWgAehrpGdEVu
        gHBhzuoPrRGtmBGFuHfUW8FMlN23rIim0sVsI8lsP4E1U+diERwuJ0359ZbG+ep8
        L6UWwUPexqy8M7eD7FFjSF4csuhTlXTa6w4BXG6K9vgHKmhLDK4/a/pl2N7GCgG2
        9juNgdLaUSj5pp+HXinmoGE3Pg2FX+imU5axiTpzm8VvgB355RXJx4e2p9jWwvTL
        1D4DNhlsU3hubgGyRGdZyG8B9zneij5qtWLTWpADJDbEJiIWtdUE905iZ3vC7F/g
        8HrQ6Y5LePDvHzCw9VsdbvVr1CS6Jl03abxchIKB8y7U++7OsF2qNiDeFv0iRWZh
        /7m3EG4+JImquVNV2lTRjaH06Wi2dy66UpH5RK/zS39vxCFpAB95qyZJfz92rVJD
        ebO6ZtAkV+IPDcFO0sycf49YXSTbbiGHorAWQUMsCT5/TW1es5Gf7+snR8HsS7Q1
        IBgmBphlKKyzsQUjwQpqojE2+xpm4dVUcIp3s/82Nf1eT5vP9ycLtHkXeUitSw99
        Ip3R68iE5hsyiTU0msHpb288r7KJi/XmhR19gS/voOYFbrXEeiFl5pMlQ+wNUp0x
        olAhuLzIIm/SxbipNJjtqRqzk9ie+UaWVzwOLghkrDZDEnTLTGPtzX8O61vtFWnp
        SMKZ6tlH/QREYmYRcHwwaXDCL2OH1FB8eGKbzkmw1s22GWc3zb4QNvzm5B36Pnki
        N2z+G5dOHoFImHcxQrZeROJXRpYd6OxIGXYH3wJxA+/Qo5ze6hG51Vlop+mjLTQm
        pwNwzoIILxQMcuuceedaZfZKj6jGqG3UCgiqZdKFeAa9tACNMMj/Bg==
        -----END RSA PRIVATE KEY-----
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
  size        = 100
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

resource "openstack_compute_instance_v2" "slave_instances" {
  count = 3
  name      = "sjt_test_slaves_${count.index}"
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
  package_update: true
  package_upgrade: true
  packages:
    - wget
    - curl
    - apt-transport-https
    - gnupg-agent
    - software-properties-common
  runcmd:
    - echo $(date) > /var/log/timestamp
    - chown -R ubuntu:ubuntu /home/ubuntu
    - chmod 600 /home/ubuntu/.ssh/id_rsa
    - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    - apt-get update
    - apt install docker-ce=17.09.1~ce-0~ubuntu
  write_files:
    - path: /home/ubuntu/.ssh/id_rsa
      permission: 0600
      owner: ubuntu:ubuntu
      content: |
        -----BEGIN RSA PRIVATE KEY-----
        Proc-Type: 4,ENCRYPTED
        DEK-Info: DES-EDE3-CBC,24180A8361C80084

        j+rUb2zWZcCCf/z6mlXnO8flfwIen9lQG5jvDaH4ttZssLH+KcwhunsfIC+mA+Hi
        JLW4YWch3f4fYjx4m3NMRwdm1iTX3rL98Ut2gT6USmIa0Ip1qwXC2sGuRPN6ltyN
        Kgnsw8v4gRUO2fU/8WiAvUOAmCGXwWhpcbmKcU0OI8BB96wduictNJ4Yggu/Sn2q
        2np54LxeLusWXyxj0x6u72c4lVqgwbJFbf8hnoAtYp6CSvfXZhNag4aBxwO1zoD+
        Xzuf2QEa3SrJlspxsNSWhu1WBEtOwyviGblq0wEVAu2EsApSEJXwfh6gVs96zphF
        UVM3jLheUo1jIbzyu5EuINOsuFzVhUTuqb2D3YIxB4L3V7seTVjUMft1l0Ytxqpb
        /nI5PT+x5oEL9TykNc8XSVZCFBPnnEfCmXtTatuj91/+/AYaRPhtRDsKxVYOmoid
        f/xsAMPEZMJu5f/rBpldY52t6Kw+/1o6QbX/XgFoDQDlWG5zq56XRJMh59Z4YWQr
        sxDNxyuhXLVcI5m6/5ieGs9IpUsBLW8hHBi6oqBrJ9pTuUazep1/n7NdxuIdmaIk
        vXqFPu7pVNYuvBHo56MXoVSN8xEK4vktmgBxdP+q5q0D+SWhNXI6+WAa7pkKf87T
        AqIQdzLCcWEMlKLV4Pa7Tx2hGay25JRT/jTOtrfjtUkV1EGoP6McZ8ht2X4EpuVV
        nxltPNu6rKXCAFByMU1ATW06dbjpa+9FFPUvsh9nMvCJs2q3cPHxWgAehrpGdEVu
        gHBhzuoPrRGtmBGFuHfUW8FMlN23rIim0sVsI8lsP4E1U+diERwuJ0359ZbG+ep8
        L6UWwUPexqy8M7eD7FFjSF4csuhTlXTa6w4BXG6K9vgHKmhLDK4/a/pl2N7GCgG2
        9juNgdLaUSj5pp+HXinmoGE3Pg2FX+imU5axiTpzm8VvgB355RXJx4e2p9jWwvTL
        1D4DNhlsU3hubgGyRGdZyG8B9zneij5qtWLTWpADJDbEJiIWtdUE905iZ3vC7F/g
        8HrQ6Y5LePDvHzCw9VsdbvVr1CS6Jl03abxchIKB8y7U++7OsF2qNiDeFv0iRWZh
        /7m3EG4+JImquVNV2lTRjaH06Wi2dy66UpH5RK/zS39vxCFpAB95qyZJfz92rVJD
        ebO6ZtAkV+IPDcFO0sycf49YXSTbbiGHorAWQUMsCT5/TW1es5Gf7+snR8HsS7Q1
        IBgmBphlKKyzsQUjwQpqojE2+xpm4dVUcIp3s/82Nf1eT5vP9ycLtHkXeUitSw99
        Ip3R68iE5hsyiTU0msHpb288r7KJi/XmhR19gS/voOYFbrXEeiFl5pMlQ+wNUp0x
        olAhuLzIIm/SxbipNJjtqRqzk9ie+UaWVzwOLghkrDZDEnTLTGPtzX8O61vtFWnp
        SMKZ6tlH/QREYmYRcHwwaXDCL2OH1FB8eGKbzkmw1s22GWc3zb4QNvzm5B36Pnki
        N2z+G5dOHoFImHcxQrZeROJXRpYd6OxIGXYH3wJxA+/Qo5ze6hG51Vlop+mjLTQm
        pwNwzoIILxQMcuuceedaZfZKj6jGqG3UCgiqZdKFeAa9tACNMMj/Bg==
        -----END RSA PRIVATE KEY-----
  EOF

  network {
    uuid = "75ed2818-25b9-4dfa-8987-7a889dedef85"
    name = "admin-test"
  }
}

resource "openstack_blockstorage_volume_v3" "slave_volumes" {
  count = 3
  region      = "RegionOne"
  name        = "slave_volume_${count.index}"
  size        = 100
}

resource "openstack_compute_volume_attach_v2" "slave_attachments" {
  count = 3
  instance_id = "${element(openstack_compute_instance_v2.slave_instances.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v3.slave_volumes.*.id, count.index)}"
}