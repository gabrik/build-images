from debian:10-slim

LABEL authors="Gabriele Baldoni"



RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install sudo  libev-dev libssl-dev jq
COPY fog05-0.2.0.tar.gz /root/
COPY start.sh /root/
RUN cd /root && tar -xzvf fog05-0.2.0.tar.gz
COPY templates/Makefile_agent /root/agent/Makefile
RUN cd /root/agent && make install
RUN cd /root/agent && chmod +x start.sh

RUN mkdir -p /var/fos

CMD python3 /root/docker_run.py