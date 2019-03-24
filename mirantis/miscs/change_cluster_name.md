# CHANGE CLSUTER NAME

## CHANGE DOMAIN NAME

```bash
# inside /srv/salt/reclass/nodes/

# backup cfg
cp cfg01.${ORIGIN_DOMAIN_NAME}  cfg01.${ORIGIN_DOMAIN_NAME}.bak
sed -i "s/${ORIGIN_DOMAIN_NAME}/${NEW_DOMAIN_NAME}/" cfg01.${NEW_DOMAIN_NAME}

# inside /srv/salt/reclass/nodes/_generated
for i in `ls`; do sed -i "s/${ORIGIN_DOMAIN_NAME}/${NEW_DOMAIN_NAME}/" $i; done
```

## UPDATE SALT-MINION CONFIG

```bash
salt '*' saltutil.sync_all

# update salt minion configuration
salt '*' state.sls salt.minion
```

## CHAGNE CFG DOMAIN NAME

```bash
# inside /srv/salt/reclass/nodes

# backup

mv cfg01.${ORIGIN_DOMAIN_NAME} cfg01.${NEW_DOMAIN_NAME}
```

## REGENERATE RECLASS ENTRANCE FILES

```bash
# regenerate file under /srv/salt/reclass/nodes/_generated

# on cfg01
salt-call state.sls reclass
```

## UPDATE HOSTNAME

```bash
salt '*' state.sls linux.network.host
```

## UPDATE SERVICES WHICH DEPEND ON HOSTNAME

Some services use hostname as an identifier for its own, they are vulnerable for such changes and could be
malfunctional afterwards. Under such situations, manual operations might be required to fix problems.

### NOVA COMPUTE

Nova compute saves its hostname in placement database, they will generate complaints if hostname changed. Under
such situation, simple restart them could fix the problem.

### RABBITMQ

Rabbitmq also uses hostname as an identifier and hostname changing could bring [serious problems](https://stackoverflow.com/questions/14659335/rabbitmq-server-fails-to-start-after-hostname-has-changed-for-first-time) when cluster is restarted.
