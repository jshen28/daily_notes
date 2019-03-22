# PERFORMANCE TESTING

## BANDSWIDTH

### BACKGROUND

Underlaid network has a mtu of 8950 for physical NIC and switches (access/main).

Two groups of VMs are created with different mtus one of which has a mtu equal to 1450, the other got 8950. From following result, it seems that a smaller mtu will not benefit as much as a larger one. Of course, servers have the same specs across groups, on one of them, execute

```bash
iperf3 -s 0.0.0.0 -p 8888
```

On another, execute

```bash
iperf3 -c ${SERVER_ADDRESS} -p 8888
```

### RESULT

If we use mtu of 1450, clearly we cannot take full advantage of the 10Gbit/s network

```console
# iperf3 -c 192.168.20.25 -p 8888 -t 120 -i 30
Connecting to host 192.168.20.25, port 8888
[  4] local 192.168.20.8 port 34084 connected to 192.168.20.25 port 8888
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-30.00  sec  10.9 GBytes  3.13 Gbits/sec  2007   1.56 MBytes
[  4]  30.00-60.00  sec  10.7 GBytes  3.07 Gbits/sec  1746   1.74 MBytes
[  4]  60.00-90.00  sec  10.7 GBytes  3.08 Gbits/sec  1803   1.22 MBytes
[  4]  90.00-120.00 sec  10.8 GBytes  3.10 Gbits/sec  1201   1.36 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-120.00 sec  43.2 GBytes  3.09 Gbits/sec  6757             sender
[  4]   0.00-120.00 sec  43.2 GBytes  3.09 Gbits/sec                  receiver

iperf Done.
```

Meanwhile, if a mtu of 8950 is used, it seems that full bandwidth capabilities are taken,

```console
# iperf3 -c 192.168.20.8 -p 8888 -t 120 -i 30
Connecting to host 192.168.20.8, port 8888
[  4] local 192.168.20.12 port 55104 connected to 192.168.20.8 port 8888
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-30.00  sec  31.4 GBytes  8.98 Gbits/sec  155   3.03 MBytes
[  4]  30.00-60.00  sec  29.8 GBytes  8.53 Gbits/sec    6   3.03 MBytes
[  4]  60.00-90.00  sec  31.9 GBytes  9.14 Gbits/sec   17   3.03 MBytes
[  4]  90.00-120.00 sec  29.7 GBytes  8.51 Gbits/sec    0   3.03 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-120.00 sec   123 GBytes  8.79 Gbits/sec  178             sender
[  4]   0.00-120.00 sec   123 GBytes  8.79 Gbits/sec                  receiver

iperf Done.
```

## PACKET PER SECOND

### SETUP

One server is used whose specification is `6C6G40G`, make sense or not, I reserve 1G memory for each CPU. All the **six** clients use less fancy hardware: `2C2G40G`. 

On the server side, I execute

```bash
iperf3 -s 0.0.0.0 -p ${PORT} -D -A ${CPU_NO}
```

Each client will have a dedicated port and will be fired almost at the same time. The final result is a summation across all the client measurements.

### RESULLT

When `mtu=1450` and `packet_size=16`

```console
$ iperf3 -c 192.168.22.12  -u -b 8m  -i 10 -l 16 -t 1000 -p 2233
Connecting to host 192.168.22.12, port 2233
[  4] local 192.168.22.12 port 56801 connected to 192.168.22.12 port 2233
[  4] 760.00-770.00 sec  9.54 MBytes  8.00 Mbits/sec  625273
[  4] 770.00-780.00 sec  9.50 MBytes  7.97 Mbits/sec  622359
[  4] 780.00-790.00 sec  9.54 MBytes  8.00 Mbits/sec  625290
[  4] 790.00-800.00 sec  9.53 MBytes  8.00 Mbits/sec  624695
[  4] 800.00-810.00 sec  9.54 MBytes  8.00 Mbits/sec  625261
[  4] 810.00-820.00 sec  9.54 MBytes  8.00 Mbits/sec  625118
[  4] 820.00-830.00 sec  9.53 MBytes  7.99 Mbits/sec  624554
[  4] 830.00-840.00 sec  9.53 MBytes  7.99 Mbits/sec  624595
[  4] 840.00-850.00 sec  9.59 MBytes  8.04 Mbits/sec  628416
[  4] 850.00-860.00 sec  9.49 MBytes  7.96 Mbits/sec  622103
[  4] 860.00-870.00 sec  9.55 MBytes  8.01 Mbits/sec  625612
[  4] 870.00-880.00 sec  9.53 MBytes  8.00 Mbits/sec  624664
[  4] 880.00-890.00 sec  9.53 MBytes  8.00 Mbits/sec  624622
[  4] 890.00-900.00 sec  9.54 MBytes  8.00 Mbits/sec  625059
[  4] 900.00-910.00 sec  9.54 MBytes  8.00 Mbits/sec  625327
[  4] 910.00-920.00 sec  9.54 MBytes  8.01 Mbits/sec  625497
[  4] 920.00-930.00 sec  9.53 MBytes  7.99 Mbits/sec  624315
[  4] 930.00-940.00 sec  9.54 MBytes  8.00 Mbits/sec  625222
[  4] 940.00-950.00 sec  9.53 MBytes  8.00 Mbits/sec  624883
[  4] 950.00-960.00 sec  9.54 MBytes  8.00 Mbits/sec  625214
[  4] 960.00-970.00 sec  9.55 MBytes  8.01 Mbits/sec  626036
[  4] 970.00-980.00 sec  9.55 MBytes  8.01 Mbits/sec  625678
[  4] 980.00-990.00 sec  9.51 MBytes  7.98 Mbits/sec  623179
[  4] 990.00-1000.00 sec  9.54 MBytes  8.00 Mbits/sec  625079
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-1000.00 sec   954 MBytes  8.00 Mbits/sec  0.003 ms  13420084/62495281 (21%)
[  4] Sent 62495281 datagrams

iperf Done.
```

So it could be seen that `PPS` is around `60000*6=360000`.

When `mtu=8950` and `packet_size=16`, I got

```console
# iperf3 -c 192.168.20.12 -p 8888 -u -b 100m -t 60 -i 10 -l 16
Connecting to host 192.168.20.12, port 8888
[  4] local 192.168.20.8 port 34150 connected to 192.168.20.12 port 8888
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-10.00  sec  19.3 MBytes  16.2 Mbits/sec  1265739  
[  4]  10.00-20.00  sec  18.7 MBytes  15.7 Mbits/sec  1223464  
[  4]  20.00-30.00  sec  18.7 MBytes  15.7 Mbits/sec  1226616  
[  4]  30.00-40.00  sec  17.6 MBytes  14.8 Mbits/sec  1155760  
[  4]  40.00-50.00  sec  18.7 MBytes  15.7 Mbits/sec  1226559  
[  4]  50.00-60.00  sec  16.8 MBytes  14.1 Mbits/sec  1103413  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-60.00  sec   110 MBytes  15.4 Mbits/sec  0.069 ms  973/7201551 (0.014%)  
[  4] Sent 7201551 datagrams
```

## RERENCES

* [HUAWEI guide](https://support.huaweicloud.com/ecs_faq/zh-cn_topic_0115820205.html)
* [iperf documentation](https://iperf.fr/iperf-doc.php)
