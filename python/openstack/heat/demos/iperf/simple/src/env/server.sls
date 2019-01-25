sync_mine:
    cmd.run:
        - name: salt '*' mine.send network.get_hostname

{% set i = 0 %}
{% slaves_dict = salt['mine.get']('*', 'network.get_hostname') %}
{% slave_ports = {} %}
{%- for name, _ in slaves_dict.iteritems() %}

{# assume slave will have different hostnames with master #}
{%- if salt['network.get_hostname']() == name %}
{% continue %}
{% endif %}

{% do slave_ports.update({name: 8888 + i}) %}

run_iperf_for_{{ name }}:
    cmd.run:
        - name: iperf3 -s 0.0.0.0 -p {{ 8888 + i }} -A {{ i }} -D
{% set i = i + 1 %}
{% endfor %}

regenerate_pillar:
    file.managed:
        - source: salt://slave.temp
        - user: root
        - group: root
        - mode: 644
        - name: /srv/pillar/slave.sls
        - defaults:
            slave_ports: {{ slave_ports }}
