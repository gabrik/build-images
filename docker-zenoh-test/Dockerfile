from debian:10-slim

LABEL authors="Gabriele Baldoni"



RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install wget
RUN cd /root/ && wget https://www.dropbox.com/s/xsghscsfwx7zn1p/zenoh_test
RUN chmod +x /root/zenoh_test
CMD /root/zenoh_test