
{% set hostname = salt['network.get_hostname']() %}
{% set master = grains.get('master') %}

{% if pillar.get(hostname) is not none  %}

run_iperf_client:
    cmd.run:
        - name: iperf3 -c {{ master }} -p {{ pillar.get(hostname) }} -u -t 100 -i 10 -l 16 -b 8m --logfile /var/log/iperf.log &
{% endif %} 