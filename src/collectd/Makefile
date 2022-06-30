# makefile to build collectd package
#

include ../package-list.mk

WORK_DIR = collectd
TAG_DONE_FLAG := $(WORK_DIR)/.$(COLLECTD_TAG).done
BUILD_CMD = ./build.sh
CONFIG_CFLAGS = -Wno-deprecated-declarations
CONFIG_CMD =
CONFIG_CMD += ./configure
ifeq ($(COLLECTD_DEBUG), y)
CONFIG_CMD += --enable-debug
endif

LIBPQOS_DIR = $(shell echo $$LIBPQOS_DIR)
ifeq ($(LIBPQOS_DIR),)
LIBPQOS_DIR = /usr
endif

XDG_CACHE_HOME_DIR = $(shell echo $$XDG_CACHE_HOME)
ifeq ($(XDG_CACHE_HOME_DIR),)
XDG_CACHE_HOME_DIR = $(shell echo $$HOME)
endif

CONFIG_CMD += --enable-syslog
CONFIG_CMD += --enable-logfile
CONFIG_CMD += --with-libpqos=$(LIBPQOS_DIR)
CONFIG_CMD += --with-libjevents=/usr/local
CONFIG_CMD += --disable-perl
CONFIG_CMD += --with-librdkafka=/usr

CONFIG_CMD += $(COLLECTD_CONFIG_CMD_ARGS)

.PHONY: install collectd_make

all: collectd_make
	echo "Finished making $(WORK_DIR)"

# configure collectd is the process to produce the script 'configure'
$(WORK_DIR)/configure: $(TAG_DONE_FLAG)
	echo "booting up collectd"
	cd $(WORK_DIR); $(BUILD_CMD)
	echo "done booting collectd"

$(WORK_DIR)/Makefile: $(WORK_DIR)/configure
	echo "Configuring with: " $(CONFIG_CMD)
	cd $(WORK_DIR); $(CONFIG_CMD)
	echo "Configure done"

collectd_make: $(WORK_DIR)/Makefile
	$(MAKE) CFLAGS=$(CONFIG_CFLAGS) -C $(WORK_DIR) $(MORE_MAKE_FLAGS)
	echo "Make done"

install: collectd_make
	$(MAKE) CFLAGS=$(CONFIG_CFLAGS) -C $(WORK_DIR) install
	echo "Using sample configs: $(COLLECTD_CONF_VARIANT_NAME)"
	sudo DOCKER="$(DOCKER)" ./include_config.sh $(COLLECTD_CONF_VARIANT_NAME)
	sudo cp ./snmp-mibs/*.txt  /usr/share/snmp/mibs/
	echo "Make install done"

# clean repo
clean:
	cd $(WORK_DIR) && git clean -xfd *.o

$(WORK_DIR):
	git clone $(COLLECTD_URL)

$(TAG_DONE_FLAG): $(WORK_DIR)
	echo "Checking out collectd from tag: $(COLLECTD_TAG)"
	cd $(WORK_DIR); git fetch origin $(COLLECTD_TAG); git checkout FETCH_HEAD
	touch $@
