# Literal current-system evidence dispatch.  This makefile intentionally has
# no Kconfig includes or generated-config prerequisites, so receipt replay
# cannot rewrite npc/rv64/.config or launch NpcSimTop.
.PHONY: check-system-recertification-current
check-system-recertification-current:
	@python3 -B eval/ppa/tools/system_recertification_current.py verify \
	  --input npc/rv64/eval/ppa/evidence/system-recertification-current.json

.PHONY: refresh-system-recertification-current
refresh-system-recertification-current:
	@python3 -B eval/ppa/tools/system_recertification_current.py capture \
	  --output npc/rv64/eval/ppa/evidence/system-recertification-current.json
