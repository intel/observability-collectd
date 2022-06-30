# makefile to build pqos library
#

include ../package-list.mk

WORK_DIR = intel-cmt-cat
TAG_DONE_FLAG = $(WORK_DIR)/.$(LIBPQOS_TAG).done

.PHONY: install rdt_make

all: rdt_make
	echo "Finished making $(WORK_DIR)"

rdt_make: $(TAG_DONE_FLAG)
	$(MAKE) -C $(WORK_DIR)/lib $(MORE_MAKE_FLAGS)
	$(MAKE) -C $(WORK_DIR)/pqos $(MORE_MAKE_FLAGS)
	$(MAKE) -C $(WORK_DIR)/rdtset $(MORE_MAKE_FLAGS)
	echo "Make done"

install: rdt_make
	sudo $(PQOSINSTALLENV) $(MAKE) -C $(WORK_DIR) install PREFIX=/usr

# clean repo
clean:
	cd $(WORK_DIR) && git clean -xfd *.o

$(WORK_DIR):
	git clone $(LIBPQOS_URL)

$(TAG_DONE_FLAG): $(WORK_DIR)
	cd $(WORK_DIR); git fetch origin $(LIBPQOS_TAG); git checkout FETCH_HEAD
	echo "git checkout $(LIBPQOS_TAG) done"
	touch $@
