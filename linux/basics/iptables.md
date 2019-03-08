# IPTABLES COMMANDS

## OVERVIEW

```raw

--------------
|            |
|            |
| PREROUTING |
|            |
|            |
--------------


```

## NATIVE TABLES & CHAINS

```bash
iptables -t filter -A PREROUTING/FORWARD/POSTROUTING -s ${SRC} -o ${DEST} -j ${ACTION}
iptables -t nat -A PREROUTING/FORWARD/POSTROUTING -s ${SRC} -o ${DEST} -j ${ACTION}
```