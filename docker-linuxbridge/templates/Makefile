# -*-Makefile-*-

LB_PLUGIN_DIR = /etc/fos/plugins/plugin-net-linuxbridge
LB_PLUGIN_CONFFILE = $(LB_PLUGIN_DIR)/linuxbridge_plugin.json
BIN_DIR = /usr/bin

clean:
	echo "Nothing to do"
all:
	echo "Nothing to do"

install:

	mkdir -p $(LB_PLUGIN_DIR)
	sudo cp -r ./templates $(LB_PLUGIN_DIR)
	sudo cp -r ./utils $(LB_PLUGIN_DIR)
	sudo cp ./__init__.py $(LB_PLUGIN_DIR)
	sudo cp ./linuxbridge_plugin $(LB_PLUGIN_DIR)
	sudo cp ./README.md $(LB_PLUGIN_DIR)
	# sudo ln -sf /etc/fos/plugins/plugin-net-linuxbridge/linuxbridge_plugin /usr/bin/fos_linuxbridge
	sudo ln -sf $(LB_PLUGIN_DIR)/utils/get_face_address $(BIN_DIR)/fos_get_address
	sudo cp ./linuxbridge_plugin.json $(LB_PLUGIN_DIR)


