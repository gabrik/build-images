#!/bin/bash

AGENT_CONF=/etc/fos/agent.json

sh -c "echo $FOG_NODE_ID | xargs -i  jq  '.agent.uuid = \"{}\"' $AGENT_CONF > /tmp/agent.tmp && mv /tmp/agent.tmp $AGENT_CONF"
sh -c "echo tcp/$ZENOH_IP_ADDRESS:7447 | xargs -i  jq  '.agent.yaks = \"{}\"' $AGENT_CONF > /tmp/agent.tmp && mv /tmp/agent.tmp $AGENT_CONF"

/etc/fos/agent -c /etc/fos/agent.json -v