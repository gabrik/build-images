#!/bin/bash

CONF=/etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin.json

sh -c "echo $FOG_NODE_ID | xargs -i  jq  '.configuration.nodeid = \"{}\"' $CONF > /tmp/agent.tmp && mv /tmp/agent.tmp $CONF"
sh -c "echo tcp/$ZENOH_IP_ADDRESS:7447 | xargs -i  jq  '.configuration.ylocator = \"{}\"' $CONF > /tmp/agent.tmp && mv /tmp/agent.tmp $CONF"

/etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin /etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin.json