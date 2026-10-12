# Domain contracts are compiled without peer-domain RTL.
include ../../vsrc/domain-filelist.mk
DOMAIN_BUILD_DIR := $(abspath $(BUILD_DIR)/domains)
DOMAIN_NAMES := frontend execution fp control translation physical memory backend
DOMAIN_TOP_frontend := R64Frontend
DOMAIN_TOP_execution := R64ExecutionDomain
DOMAIN_TOP_fp := R64FpExecute
DOMAIN_TOP_control := R64Control
DOMAIN_TOP_translation := R64DataTranslationService
DOMAIN_TOP_physical := R64PhysicalMemory
DOMAIN_TOP_memory := R64Memory
DOMAIN_TOP_backend := R64Backend
DOMAIN_SRCS_frontend := $(R64_FRONTEND_SRCS)
DOMAIN_SRCS_execution := $(R64_EXECUTION_SRCS)
DOMAIN_SRCS_fp := $(R64_FP_SRCS)
DOMAIN_SRCS_control := $(R64_CONTROL_SRCS)
DOMAIN_SRCS_translation := $(R64_TRANSLATION_SRCS)
DOMAIN_SRCS_physical := $(R64_PHYSICAL_SRCS)
DOMAIN_SRCS_memory := $(R64_MEMORY_SRCS)
DOMAIN_SRCS_backend := $(R64_BACKEND_SRCS)

.PHONY: domain-lint domain-run
domain-lint: $(DOMAIN_NAMES:%=domain-lint-%)
$(DOMAIN_BUILD_DIR):
	mkdir -p $@
define R64_DOMAIN_LINT
.PHONY: domain-lint-$(1)
domain-lint-$(1): | $(DOMAIN_BUILD_DIR)
	verilator --lint-only --top-module $$(DOMAIN_TOP_$(1)) --assert -DR64_ASSERT $$(CORE_LINT_FLAGS) -I../../vsrc/include -I../../vsrc/backend -I../../vsrc/platform $$(DOMAIN_SRCS_$(1)) > $(DOMAIN_BUILD_DIR)/$(1)-lint.log 2>&1
endef
$(foreach domain,$(DOMAIN_NAMES),$(eval $(call R64_DOMAIN_LINT,$(domain))))

DOMAIN_TESTS := tb_r64_recovery_inbox tb_r64_memory_effect_lease tb_r64_execution_owners tb_r64_lsu_response_ingress tb_r64_execution_domain tb_r64_control_domain tb_r64_data_translation_service tb_r64_fp_qcredit tb_r64_frontend tb_r64_lsu_network
DOMAIN_TEST_SRCS_tb_r64_execution_domain := $(R64_EXECUTION_SRCS)
DOMAIN_TEST_SRCS_tb_r64_control_domain := $(R64_CONTROL_SRCS)
DOMAIN_TEST_SRCS_tb_r64_data_translation_service := $(R64_TRANSLATION_SRCS)
DOMAIN_TEST_SRCS_tb_r64_fp_qcredit := $(R64_FP_SRCS)
DOMAIN_TEST_SRCS_tb_r64_frontend := $(R64_FRONTEND_SRCS) $(R64_RTL_ROOT)/bus/R64AxiRead.v
DOMAIN_TEST_SRCS_tb_r64_lsu_network := $(R64_MEMORY_SRCS) oracles/R64TranslationTokenEcho.v
DOMAIN_TEST_SRCS_tb_r64_recovery_inbox := $(R64_RTL_ROOT)/common/R64RecoveryInbox.v
DOMAIN_TEST_SRCS_tb_r64_memory_effect_lease := $(R64_RTL_ROOT)/control/R64MemoryEffectLease.v
DOMAIN_TEST_SRCS_tb_r64_execution_owners := $(R64_RTL_ROOT)/backend/R64ExecutionOwners.v
DOMAIN_TEST_SRCS_tb_r64_lsu_response_ingress := $(R64_RTL_ROOT)/lsu/R64LsuResponseIngress.v
domain-run: $(DOMAIN_TESTS:%=$(DOMAIN_BUILD_DIR)/%.pass)
define R64_DOMAIN_TEST
$(DOMAIN_BUILD_DIR)/$(1).vvp: modules/$(1).sv $$(DOMAIN_TEST_SRCS_$(1)) $$(R64_RTL_HDRS) $$(TEST_HEADERS) domain-tests.mk ../../vsrc/domain-filelist.mk | $(DOMAIN_BUILD_DIR)
	$(IVERILOG) -g2012 -DR64_ASSERT -I modules -I ../../vsrc/include -I ../../vsrc/backend -I ../../vsrc/platform -s $(1) -o $$@ $$(DOMAIN_TEST_SRCS_$(1)) $$<
$(DOMAIN_BUILD_DIR)/$(1).pass: $(DOMAIN_BUILD_DIR)/$(1).vvp
	timeout 60 $(VVP) $$< > $(DOMAIN_BUILD_DIR)/$(1).log 2>&1
	rg -F '[PASS] $(1)' $(DOMAIN_BUILD_DIR)/$(1).log
	touch $$@
endef
$(foreach test,$(DOMAIN_TESTS),$(eval $(call R64_DOMAIN_TEST,$(test))))
