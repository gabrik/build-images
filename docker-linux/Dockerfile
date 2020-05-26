from debian:10-slim

LABEL authors="Gabriele Baldoni"



RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install sudo make python3 python3-pip jq git wget
COPY libzenoh-0.3.0-Linux.deb /root/
RUN dpkg -i /root/libzenoh-0.3.0-Linux.deb
COPY start.sh /root/
RUN pip3 install pyangbind sphinx psutil netifaces jinja2 zenoh==0.3.0 yaks==0.3.0.post1
RUN cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python/ && cd sdk-python && make && make install
RUN cd /root && git clone https://github.com/eclipse-fog05/api-python/ && cd api-python && make install
RUN cd /root && git clone https://github.com/eclipse-fog05/plugin-os-linux
COPY templates/Makefile /root/plugin-os-linux/Makefile
RUN cd /root/plugin-os-linux && make install
RUN mkdir -p /etc/fos
RUN cd /root && chmod +x start.sh

RUN mkdir -p /var/fos

CMD /root/start.sh