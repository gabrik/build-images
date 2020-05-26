import uuid
import json
import sys
import os
import time
import requests
import psutil
from subprocess import PIPE
import copy
from mvar import MVar
import signal


def read_file(filepath):
    with open(filepath, 'r') as f:
        data = f.read()
    return data

def write_file(filepath, content):
    with open(filepath, 'w') as f:
        tot = f.write(content)
        f.flush()
    return tot

def remove_file(filepath):
    return os.remove(filepath)

def generate_uuids(total):
    uuids = []
    for i in range(0,total):
        uid = '{}'.format(uuid.UUID(int=i))
        uuids.append(uid)
    return uuids




def main():

    uid = os.environ.get('FOG_NODE_ID', '{}'.format(uuid.uuid4()))
    zenoh = os.environ.get('ZENOH_IP_ADDRESS')
    if zenoh is None:
        print('Missing ZENOH_IP_ADDRESS environment variable')
        exit(-1)
    var = MVar()

    print('Eclipse fog05 v0.2.0\n')
    print('Node ID: {}\n'.format(uid))
    print('Zenoh IP: {}\n'.format(zenoh))

    def catch(signal, _):
        print('Received {}\n'.format(signal))
        if signal in [2, 15]:
            var.put(signal)


    template_agent = json.loads(read_file('/etc/fos/agent.json'))
    linux_template = json.loads(read_file('/etc/fos/plugins/plugin-os-linux/linux_plugin.json'))
    lb_template = json.loads(read_file('/etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin.json'))
    native_template =  json.loads(read_file('/etc/fos/plugins/plugin-fdu-native/native_plugin.json'))


    node = {
        'configurations':[],
        'processes':[],
        'files':[]
    }

    agent_conf = copy.deepcopy(template_agent)
    agent_conf['agent']['yaks'] = 'tcp/{}:7447'.format(zenoh)
    agent_conf['agent']['uuid'] = uid

    linux_conf = copy.deepcopy(linux_template)
    linux_conf['configuration']['ylocator'] = 'tcp/{}:7447'.format(zenoh)
    linux_conf['configuration']['nodeid'] = uid

    lb_conf = copy.deepcopy(lb_template)
    lb_conf['configuration']['ylocator'] = 'tcp/{}:7447'.format(zenoh)
    lb_conf['configuration']['nodeid'] = uid

    native_conf = copy.deepcopy(native_template)
    native_conf['configuration']['ylocator'] = 'tcp/{}:7447'.format(zenoh)
    native_conf['configuration']['nodeid'] = uid

    agent_file = '/tmp/agent_{}.json'.format(uid)
    linux_file = '/tmp/linux_{}.json'.format(uid)
    lb_file = '/tmp/lb_{}.json'.format(uid)
    native_file = '/tmp/native_{}.json'.format(uid)

    agent_out = '/tmp/agent_{}.out'.format(uid)
    linux_out = '/tmp/linux_{}.out'.format(uid)
    lb_out = '/tmp/lb_{}.out'.format(uid)
    native_out = '/tmp/native_{}.out'.format(uid)

    write_file(agent_file, json.dumps(agent_conf))
    write_file(linux_file, json.dumps(linux_conf))
    write_file(lb_file, json.dumps(lb_conf))
    write_file(native_file, json.dumps(native_conf))

    node['configurations'].append(agent_file)
    node['configurations'].append(linux_file)
    node['configurations'].append(lb_file)
    node['configurations'].append(native_file)
    # out
    node['configurations'].append(agent_out)
    node['configurations'].append(linux_out)
    node['configurations'].append(lb_out)
    node['configurations'].append(native_out)

    cmd_agent = '/etc/fos/agent -c {} -v'.format(agent_file)
    f_agent = open(agent_out,'w')

    cmd_linux = '/etc/fos/plugins/plugin-os-linux/linux_plugin {}'.format(linux_file)
    f_linux = open(linux_out,'w')

    cmd_lb = '/etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin {}'.format(lb_file)
    f_lb = open(lb_out,'w')

    cmd_native = '/etc/fos/plugins/plugin-fdu-native/native_plugin {}'.format(native_file)
    f_native = open(native_out,'w')

    p_agent = psutil.Popen(cmd_agent.split(' '), shell=False, stdout=f_agent, stderr=f_agent, stdin=PIPE)
    p_linux = psutil.Popen(cmd_linux.split(' '), shell=False, stdout=f_linux, stderr=f_linux, stdin=PIPE)
    p_lb = psutil.Popen(cmd_lb.split(' '), shell=False, stdout=f_lb, stderr=f_lb, stdin=PIPE)
    p_native = psutil.Popen(cmd_native.split(' '), shell=False, stdout=f_native, stderr=f_native, stdin=PIPE)

    node['processes'].append(p_native)
    node['processes'].append(p_lb)
    node['processes'].append(p_linux)
    node['processes'].append(p_agent)

    node['files'].append(f_native)
    node['files'].append(f_lb)
    node['files'].append(f_linux)
    node['files'].append(f_agent)

    signal.signal(signal.SIGINT,catch)
    signal.signal(signal.SIGTERM, catch)

    var.get()



    for p in node['processes']:
        pid = p.terminate()
    for f in node['files']:
        f.close()
    for f in node['configurations']:
        remove_file(f)

    print('Bye')
    exit(0)



if __name__=='__main__':
    main()
