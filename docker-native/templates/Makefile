# -*-Makefile-*-


NATIVE_PLUGIN_DIR = /etc/fos/plugins/plugin-fdu-native
PLUGIN_CONF = $(NATIVE_PLUGIN_DIR)/native_plugin.json

BIN_DIR = /usr/bin


all:
	mkdir -p utils
	gcc -o utils/containerize containerize.c

clean:
	rm -rf utils/containerize


install:

	mkdir -p $(NATIVE_PLUGIN_DIR)
	sudo cp -r ./templates $(NATIVE_PLUGIN_DIR)
	sudo cp -r ./templates_no_isolation $(NATIVE_PLUGIN_DIR)
	sudo cp -r ./utils $(NATIVE_PLUGIN_DIR)
	sudo cp ./__init__.py $(NATIVE_PLUGIN_DIR)
	sudo cp ./isolation.py $(NATIVE_PLUGIN_DIR)
	sudo cp ./no_isolation.py $(NATIVE_PLUGIN_DIR)
	sudo cp ./native_plugin $(NATIVE_PLUGIN_DIR)
	sudo cp ./NativeFDU.py $(NATIVE_PLUGIN_DIR)
	sudo cp ./NativeNoIsolationFDU.py $(NATIVE_PLUGIN_DIR)
	sudo cp ./README.md $(NATIVE_PLUGIN_DIR)
	sudo cp ./native_plugin.json $(PLUGIN_CONF)
	sudo chmod +x $(NATIVE_PLUGIN_DIR)/utils/containerize
	sudo ln -sf $(NATIVE_PLUGIN_DIR)/utils/containerize $(BIN_DIR)/fos_containerize
