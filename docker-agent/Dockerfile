from debian:10-slim

LABEL authors="Gabriele Baldoni"



RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install libev-dev libssl-dev jq
COPY fog05-0.2.0.tar.gz /root/
COPY start.sh /root/
RUN cd /root && tar -xzvf fog05-0.2.0.tar.gz
RUN mkdir -p /etc/fos
RUN install -m 0755 /root/agent/_build/default/fos-agent/fos_agent.exe /etc/fos/agent
RUN install /root/agent/etc/agent.json  /etc/fos/agent.json
RUN cd /root && chmod +x start.sh

RUN mkdir -p /var/fos

CMD /root/start.sh