# NOTES

## INSTALLATION

```sh
virtualenv ${TEMPEST_PATH}
cat > ${TEMPEST_PATH}/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF
source ${TEMPEST_PATH}/bin/activate
cd ${TEMPEST_PATH}
git clone https://github.com/openstack/tempest.git
pip install tempest/
```

## BASIC COMMANDS

```sh
tempest init ${WORKSPACE_NAME}
cd ${WORKSPACE_NAME}
tempest run
```

## CONFIGURATION

### TEMPEST CONFIGURATION FILE

`Tempest` has a configuration file named `tempest.conf` residues in `${WORKSPACE_PATH}/etc/tempest.conf`. In this file, user should provide `username`, `password`, etc. One can inspect `config.py` to get a full list of options. There are some pretty convenient options. For example, you can disable all `swift` services by adding `swift = False` under `[service_available]` section.

### CLI PARAMETERS

Tempest supports extra configuration parameters by adding new options such as `--whitelist-file`, `--blacklist-file` or `--load-list`. Available tests could be displayed by hitting `tempest run -l` and it will only generate tests that will be executed under current configuraiton. This enables you to check up configurations before launching tests.

## CODE

### TEST FILES

Test files are located in `api`, `scenario` and `tests`, whereas the first two are about testing existing openstack cloud while the last one aims at testing tempest itself. `api` tests are mainly for validating standalone URLs while `scenario` test seems to be some sort of intergration testing. So if you run smoke tests, `scenario` will be skipped.

### CLIENT

It seems to me, but I still need more time to read and interpret code, that `tempest` basically wraps http(s) requests itself without using 3rd party clients.