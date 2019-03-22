#!/usr/bin/env python

from sys import argv
import nova.conf
from nova import config
from nova import context
from nova.objects import register_all
from nova.scheduler.host_manager import HostManager
from oslo_config import cfg
from nova.db.sqlalchemy import api

import logging

logging.basicConfig(level=logging.INFO)


if __name__ == '__main__':

    # register objects
    register_all()
    CONF = cfg.CONF
    CONF(
      project='host-test',
    )

    # host manager should use [api_database] connection
    api.configure(CONF)

    # print all host states
    hm = HostManager()
    for i in hm.get_all_host_states(context.get_admin_context()):
        print(i.nodename, i.uuid, i.disk_mb_used, i.free_ram_mb, i.cpu_info)
