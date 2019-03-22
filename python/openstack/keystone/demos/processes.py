import eventlet
import os
import sys
import time
from keystoneauth1 import session, loading


def init_neutron_client(credentials):

    # relation between variable name & corresponding environment variable
    required_fields = {'auth_url': 'OS_AUTH_URL',
                       'username': "OS_USERNAME",
                       'password': 'OS_PASSWORD',
                       'project_name': "OS_PROJECT_NAME",
                       'project_domain_name': "OS_PROJECT_DOMAIN_NAME",
                       "access_token_endpoint": "OS_ACCESS_TOKEN_ENDPOINT",
                       "client_id": "OS_CLIENT_ID",
                       "client_secret": "OS_CLIENT_SECRET",
                       "identity_provider": "OS_IDENTITY_PROVIDER",
                       "protocol": "OS_PROTOCOL"
                       }

    # check & pop values from environment variable
    options = {}
    for key in required_fields.keys():
        if not credentials.get(key):
            value = os.environ[required_fields[key]]
            if not value:
                raise Exception("%s(%s) is missing" % (key, required_fields[key]))
            options.update({key: value})
        else:
            options.update({key: credentials.get(key)})

    loader = loading.get_plugin_loader('v3oidcpassword')
    auth = loader.load_from_options(**options)
    sess = session.Session(auth=auth, verify=False)

    return sess.get_token()
    

def worker(input_var):
    token, url = input_var
    print(time.time())
    print (token, url)
    # return os.system('curl -XGET -H "x-auth-token: %s" %s' % (token, url))


if __name__ == "__main__":
    eventlet.monkey_patch()
    pool = eventlet.greenpool.GreenPool(100)
    tokens = []
    for i in range(0, 15):
        tokens.append(init_neutron_client({}))

    for result in pool.imap(worker, zip(tokens, [sys.argv[1]]*15)):
        print(result)
    
