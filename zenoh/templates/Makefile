#
# Copyright (c) 2017, 2020 ADLINK Technology Inc.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0, or the Apache License, Version 2.0
# which is available at https://www.apache.org/licenses/LICENSE-2.0.
#
# SPDX-License-Identifier: EPL-2.0 OR Apache-2.0
#
# Contributors:
#   ADLINK zenoh team, <zenoh@adlink-labs.tech>
#

SYSTEMD_DIR = /lib/systemd/system/
ZENOH_DIR = /etc/zenoh

.PHONY: all release test doc install clean uninstall

all:
	dune build @all --profile release

install:

ifeq "$(wildcard $(ZENOH_DIR))" ""
	sudo mkdir -p $(ZENOH_DIR)
	install -m 0755 _build/default/src/zenoh-router-daemon/zenohd.exe $(ZENOH_DIR)/zenohd
	install _build/default/src/yaks/yaks-plugin.cmxs $(ZENOH_DIR)/yaks-plugin.cmxs
else
	install -m 0755 _build/default/src/zenoh-router-daemon/zenohd.exe $(ZENOH_DIR)/zenohd
	install _build/default/src/yaks/yaks-plugin.cmxs $(ZENOH_DIR)/yaks-plugin.cmxs
endif
	sudo cp zenoh.service $(SYSTEMD_DIR)

clean:
	dune clean

uninstall:
	dune uninstall