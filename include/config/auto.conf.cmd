deps_config := \
	npc/single/Kconfig

include/config/auto.conf: \
	$(deps_config)


$(deps_config): ;
