# Upstream Package List
#
# Every tag is defined as its suggested default
# value, it can always be overriden when invoking Make

LIBPQOS_URL = https://github.com/01org/intel-cmt-cat.git
LIBPQOS_TAG ?= v4.3.0

PMUTOOLS_URL = https://github.com/andikleen/pmu-tools
PMUTOOLS_TAG ?= master

# collectd section
COLLECTD_URL = https://github.com/collectd/collectd

# there are 2 collectd flavors:
# -"stable" - based on stable collectd release
# -"latest" - development version, based on main branch
ifeq ($(COLLECTD_FLAVOR), stable)
# using the most recent stable release
	COLLECTD_TAG ?= 54f769929d7aafc8dd5162616af19a8e60cd5ae2
	COLLECTD_CONF_VARIANT_NAME = sample_configs-stable
endif
ifeq ($(COLLECTD_FLAVOR), latest)
# collectd code from main branch
	COLLECTD_TAG ?= main
	COLLECTD_CONF_VARIANT_NAME = sample_configs-latest
endif

echo "Using COLLECTD_TAG: $(COLLECTD_TAG)"
echo "Using COLLECTD_CONF_VARIANT_NAME: $(COLLECTD_CONF_VARIANT_NAME)"
