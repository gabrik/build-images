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
FORCE_DIR = /etc/force
LOCAL_BIN = /usr/local/bin/

all:
	go build -o force src/app.go src/force.go src/main.go


clean:
	rm -rf force

install:

ifeq "$(wildcard $(FORCE_DIR))" ""
	sudo mkdir -p $(FORCE_DIR)
	install -m 0755 force $(FORCE_DIR)/force
	install etc/force.json $(FORCE_DIR)/force.json
else
	install -m 0755 force $(FORCE_DIR)/force
	install etc/force.json $(FORCE_DIR)/force.json
endif
	sudo cp force.service $(SYSTEMD_DIR)


ln -s $(FORCE_DIR)/force $(LOCAL_BIN)/force