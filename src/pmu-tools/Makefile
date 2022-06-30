# makefile to build jevents library
#

include ../package-list.mk
export XDG_CACHE_HOME=/usr/local/src
WORK_DIR = pmu-tools
TAG_DONE_FLAG = $(WORK_DIR)/.$(PMUTOOLS_TAG).done
MAKEFILE = Makefile

.PHONY: install jevents_make

all: jevents_make
	echo "Finished making $(WORK_DIR)"

jevents_make: $(TAG_DONE_FLAG)
	cd $(WORK_DIR)/jevents
	sed -i 's/lib64/lib/' $(WORK_DIR)/jevents/$(MAKEFILE)
	sed -i 's/CFLAGS := -g -Wall -O2 -Wno-unused-result/CFLAGS := -g -Wall -O2 -Wno-unused-result -fPIC/' $(WORK_DIR)/jevents/$(MAKEFILE)
	$(MAKE) -C $(WORK_DIR)/jevents
	echo "Make done"

install: jevents_make
	sudo $(MAKE) -C $(WORK_DIR)/jevents install
	./$(WORK_DIR)/event_download.py --all


# clean repo
clean:
	cd $(WORK_DIR) && git clean -xfd *.o

$(WORK_DIR):
	git clone $(PMUTOOLS_URL)

$(TAG_DONE_FLAG): $(WORK_DIR)
	cd $(WORK_DIR); git fetch origin $(PMUTOOLS_TAG); git checkout FETCH_HEAD
	echo "git checkout $(PMUTOOLS_TAG) done"
	touch $@
