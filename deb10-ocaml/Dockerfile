from debian:10-slim

LABEL authors="Gabriele Baldoni"



RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential devscripts lintian dh-make git wget jq libev-dev libssl-dev m4 pkg-config rsync unzip cmake sudo && \
    DEBIAN_FRONTEND=noninteractive wget -O opam https://github.com/ocaml/opam/releases/download/2.0.6/opam-2.0.6-x86_64-linux &&\
    install ./opam /usr/local/bin/opam &&\
    opam init --compiler=4.09.0 --disable-sandboxing &&\
    bash -c 'printf "eval $(opam env)" >> /root/.profile' &&\
    bash -c "opam install dune.1.11.4 atdgen.2.0.0 conf-libev ocp-ocamlres websocket-lwt.2.12 -y" &&\
    bash -c "opam pin add apero-core https://github.com/atolab/apero-core.git#0.4.6 -y" &&\
    bash -c "opam pin add dynload-sys https://github.com/atolab/apero-core.git#0.4.6 -y" &&\
    bash -c "opam pin add apero-net https://github.com/atolab/apero-net.git#0.4.6 -y" &&\
    bash -c "opam pin add apero-time https://github.com/atolab/apero-time.git#0.4.6 -y" &&\
    bash -c "opam pin add zenoh-proto https://github.com/atolab/zenoh.git#0.3.0 -y" &&\
    bash -c "opam pin add zenoh-ocaml https://github.com/atolab/zenoh.git#0.3.0 -y" &&\
    bash -c "opam pin add yaks-common https://github.com/atolab/yaks-common.git#0.3.0 -y" &&\
    bash -c "opam pin add yaks-ocaml https://github.com/atolab/yaks-ocaml.git#0.3.0 -y"

CMD /usr/bin/bash

