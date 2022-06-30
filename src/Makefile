# Top Makefile to build upstream packages.
#

SUBDIRS =
ifeq ($(BUILD_LIBPQOS), y)
SUBDIRS += libpqos
endif
ifeq ($(BUILD_PMU_TOOLS), y)
SUBDIRS += pmu-tools
endif
SUBDIRS += collectd

.PHONY: all install clean $(SUBDIRS)
all install clean: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
