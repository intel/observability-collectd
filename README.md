# observability-collectd

**Observability collectd** is a containerized version of [Collectd](https://github.com/collectd/collectd).
The goal is to produce minimal size docker image based on Alpine linux that has most of collectd available plugins.

## Minimum requirements
- [Linux kernel](https://en.wikipedia.org/wiki/Linux_kernel) version 3.13 or later.
- Docker version 20.10.6
## Pre-configuration
Supported plugins [enabled by default](#enabled-by-default-plugins) does not require any additional configuration and run immediately after the start of the container. 
By default no additional configuration is required. 

To get metrics metrics from plugins [disabled by default](#disabled-by-default-plugins) or [unsupported](#unsupported-plugins) user should provide appropriate configuration and install required dependencies on host machine. For more information on required configuration for these plugins please follow [collectd wiki](https://collectd.org/wiki/index.php/Table_of_Plugins) pages. User should remember to uncomment required configuration files located in `src/collectd/sample_configs-stable`, `src/collectd/sample_configs-latest` (depending on chosen `--flavor`) or custom location (if `--config_path` is provided) **before** container creation and also to deliver own configuration files for [unsupported plugins](#unsupported-plugins).

---
## Installation

1. Install Docker 20.10.6. or newer. [Docker installation guide](https://docs.docker.com/engine/install/)
1. Clone **Observability-collectd** repository
2. `cd observability-collectd`
3. Execute `./collectd_intel_docker.sh build-run <image-name> <container-name>` command to build and run Docker container in default [stable flavor](#optional-config-flags)
4. Execute `./collectd_intel_docker.sh logs <container-name>` to watch logs
5. Browse files in `/tmp/collectd/` on host to see provided metrics

**Observability-collectd** is prepared to run single instance of image. It is not recommended to start more than one container in parallel.

---
## How to use it

- See **available options** with:

`
./collectd_intel_docker.sh
`

- **Build and run** observability-collectd container: 

`
./collectd_intel_docker.sh build-run <image-name> <container-name>
`

- **Build** observability-collectd image:

`
./collectd_intel_docker.sh build <image-name>
`

- **Run** observability-collectd Docker image:

`
./collectd_intel_docker.sh run <image-name> <container-name>
`

- **Restart** observability-collectd container (equivalent to: `docker restart <container-name>`): 

`
./collectd_intel_docker.sh restart <container-name>
`

- **Stop and remove** observability-collectd container and images linked to it: 

`
./collectd_intel_docker.sh remove <image-name> <container-name>
`

- **Remove** observability-collectd images:

`
./collectd_intel_docker.sh remove-build <image-name>
`

- **Enter** observability-collectd container via the bash: 

`
./collectd_intel_docker.sh enter <container-name>
`

- See collectd **logs** with: 

`
./collectd_intel_docker.sh logs <container-name>
`

## Other container operations

Observability-collectd is based on Docker. When user creates, builds and runs containers everything behind the scenes is managed by Docker. This is why user can either use `collectd_intel_docker.sh` script to prepare some containers operations (restart, logs, etc.) or pure Docker commands like `docker restart <container-name>`, `docker logs <container-name>`.

## Optional config flags
There are also additional **flags** that can be used for building the image or running the container.

- **--flavor** can be used to set the collectd version for image build. It can be set to one of **stable** or **latest**.
The **stable** means most recent *stable commit* from main branch. *Stable commit* has been arbitrarily chosen as 
[54f7699](https://github.com/collectd/collectd/commit/54f769929d7aafc8dd5162616af19a8e60cd5ae2). 
The **latest** is the most recent code from main branch (experimental feature). By default the build is made basing on **stable** flavor.

`
./collectd_intel_docker.sh build-run <image-name> <container-name> --flavor stable
`

- **--config_path** can be used to set the alternative host directory with plugins configuration when running the container. It mounts provided path as volume for container. It is not recommended to mount potentialy insecure locations (eg. /tmp), it is better to mount something like `/home/user/collectd_configuration/`. **Do not provide here path to single configuration file. This option is intended to provide a ***directory*** with configuration files for particular plugins.**

`
./collectd_intel_docker.sh run <image-name> <container-name> --config_path /opt/collectd/etc/collectd.conf.d/
`

- **--mount_dir** option can be used to mount custom directories and files in a container (this works as a Docker volume in `rw` mode). This option can be used multiple times to mount multiple directories or files. Format of parameter is `/path/on/host:/path/in/container`. Path on host must point to existing directory or file. Path in a container is verified by a Docker engine and also must point to accessible resource. This option is very useful for mounting resources of plugins that are [disabled by default](#supported-plugins-disabled-by-default) or [unsupported](#unsupported-plugins).\
<br>It is recommended to mount into a container only those resources from the host system that are required by individual plugins.\
**Avoid mounting the entire `/var/run/` directory to prevent inadvertent mounting hosts' docker socket file and other sensitive resources inside the container.**\
Please refer to the collectd [documentation](https://collectd.org/wiki/index.php/Table_of_Plugins) to determine the requirements of each plugin. Details on configuring individual plugins can be found in the collectd repository file: [colectd.conf.pod](https://github.com/collectd/collectd/blob/main/src/collectd.conf.pod)\
<br>Example below mounts DPDK root directory to enable DPDK plugin to access DPDK socket on host, it also mounts user-owned directory `collectd_metrics` to enable user an easy access to collectd metrics:

`
./collectd_intel_docker.sh run <image-name> <container-name> --mount_dir /var/run/dpdk:/var/run/dpdk --mount_dir /home/user/collectd_metrics:/tmp/collectd
`

### Default behavior
There are few possible combinations of **--flavor** and **--config_path** flags:
- by default if no **--flavor** or **--config_path** option is set then **stable** container is built with default **stable** configuration
- if only **--flavor** flag is set then appropriate configuration is provided for the build (**stable** or **latest**)
- if only **--config_path** is set then build is made **stable** with given path for configuration
- if both **--flavor** and **--config_path** is set then given configuration path is set for chosen flavor

### Environment variables
For image build some of the host environmental variables are used.

- **COLLECTD_DEBUG** - if set to *y*, the [Collectd](https://github.com/collectd/collectd) will be build with debug
logs enabled, otherwise debug is disabled. It can be set for single build, for example:

`
COLLECTD_DEBUG=y ./collectd_intel_docker.sh build 
`

- **http_proxy** and **https_proxy** - if set on host system, the proxy will be used during image build for
network connectivity.

---
## collectd configuration
The main collectd configuration file is located in `src/collectd/collectd.conf`.
It loads all files with plugins configuration from default (`src/collectd/sample_configs-stable`) or specified (`--config_path`) directory.

To modify the settings of particular plugin modify the corresponding file, for example:
`src/collectd/sample_configs-stable/mcelog.conf`.

By default all configuration files are copied into image, so when user would like to edit and reload configuration there are two possible scenarios:

1. rebuild and run image and container from scratch using `build`, `run` or `build-run` commands
2. use existing image and create container with `run` command and `--config_path` option provided to mount volume with new configuration files into container. See [usage examples](#usage-examples).

To ensure everything is correct user can check collectd logs with `./collectd_intel_docker.sh logs collectd-cnt` command. 

---
## Plugins available in observability-collectd
Observability-collectd is build with set of plugins. They are divided into two groups: [supported](#supported-plugins-enabled-by-default) and [unsupported](#unsupported-plugins). Supported ones are partialy [disabled](#supported-plugins-disabled-by-default) by configuration files. 

 All of the plugins can be enabled but some of them ([disabled](#supported-plugins-disabled-by-default) and [unsupported](#unsupported-plugins)) require specific configuration and dependencies installed on host system. Unsupported plugins are normally compiled with all the others inside image but are not tested and user need to provide configuration files for them.
### Supported plugins enabled by default
1. capabilities
2. contextswitch
3. cpu
4. csv
5. df
6. disk
7. ethstat
8. exec
9. hugepages
10. intel_rdt
11. ipc
12. irq
13. load
14. logfile
15. memory
16. netlink
17. numa
18. pcie_errors
19. processes
20. smart
21. swap
22. turbostat
23. uptime
24. write_prometheus

### Supported plugins disabled by default
1. cpufreq
2. dpdk_telemetry
3. intel_pmu
4. ipmi
5. logparser
6. mcelog
7. network
8. ovs_events
9. ovs_stats
10. python
11. ras
12. snmp_agent
13. unixsock
14. virt
15. write_http
16. write_kafka
17. write_log

### Unsupported plugins
1. aggregation
2. amqp
3. apache
4. apcups
5. ascent
6. battery
7. bind
8. buddyinfo
9. ceph
10. cgroups
11. chrony
12. check_uptime
13. connectivity
14. conntrack
15. cpusleep
16. curl
17. curl_json
18. curl_xml
19. dbi
20. dns
21. drbd
22. email
23. entropy
24. fhcount
25. filecount
26. fscache
27. hddtemp
28. infiniband
29. interface
30. iptables
31. ipvs
32. log_logstash
33. madwifi
34. match_empty_counter
35. match_hashed
36. match_regex
37. match_timediff
38. match_value
39. mbmon
40. md
41. mdevents
42. memcachec
43. memcached
44. multimeter
45. mysql
46. nfs
47. nginx
48. notify_desktop
49. notify_nagios
50. ntpd
51. olsrd
52. openldap
53. openvpn
54. pinba
55. ping
56. postgresql
57. powerdns
58. procevent
59. protocols
60. redis
61. rrdcached
62. rrdtool
63. sensors
64. serial
65. snmp
66. statsd
67. synproxy
68. sysevent
69. syslog
70. table
71. tail_csv
72. tail
73. target_notification
74. target_replace
75. target_scale
76. target_set
77. target_v5upgrade
78. tcpconns
79. teamspeak2
80. ted
81. thermal
82. threshold
83. ubi
84. users
85. uuid
86. vmem
87. vserver
88. wireless
89. write_graphite
90. write_influxdb_udp
91. write_mongodb
92. write_redis
93. write_sensu
94. write_stackdriver
95. write_syslog
96. write_tsdb
97. zfs_arc
98. zookeeper

---
## Usage examples

- Creating and running Collectd Docker image: 

`
./collectd_intel_docker.sh build-run collectd-img collectd-cnt
`
  
This command will create and run CollectD Docker image with given `collectd-img` name and run it as a `collectd-cnt` named container.

- Building just the image and running it later with a separate command:

`
./collectd_intel_docker.sh build collectd-img
`

`
./collectd_intel_docker.sh run collectd-img collectd-cnt
`

- To see logs from collectd in the container:

`
./collectd_intel_docker.sh logs collectd-cnt
`

To exit viewing logs press: `CTRL + C`.


- To load new collectd configuration files:

`
./collectd_intel_docker.sh run collectd-img collectd-cnt --config_path /home/user/collectd_config/
`

This will use existing `collectd-img` image and create container with custom configuration provided. If `collectd-cnt` already exists it needs to be removed with `docker rm collectd-cnt` command.
