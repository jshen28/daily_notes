
{% set hostname = salt['network.get_hostname']() %}
{% set master = grains.get('master') %}

run_iperf_client:
    cmd.run:
        - name: iperf3 -c {{ master }} -p {{ pillar.get(hostname) }} -u -t 100 -i 10 -l 16 -b 10m >> /var/log/iperf.log