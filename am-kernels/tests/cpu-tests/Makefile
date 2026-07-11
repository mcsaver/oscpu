.PHONY: all run gdb clean latest c prepare-result check-results $(ALL)

##结果文件：由 prepare-result 在实际运行测试前初始化
RESULT = .result

##颜色定义
COLOR_RED   = \033[1;31m
COLOR_GREEN = \033[1;32m
COLOR_NONE  = \033[0m

##测试集合，自动扫描test/*.c，生成测试名列表
ALL = $(basename $(notdir $(shell find tests/. -name "*.c")))

##all目标，为每个测试生成临时Makefile.<test>并构建，随后打印测试列表
all: $(addprefix Makefile., $(ALL))
	@echo "test list [$(words $(ALL)) item(s)]:" $(ALL)

##测试入口，运行make dummy这类写法，实际触发Makefile.dummy
$(ALL): %: Makefile.%

##临时Makefile规则
##1.生成临时Makefile(设置NAME/SRCS并include Makefile)
##2.用该Makefile构建并运行当前目标
##3.将PASS/FAIL写入.result
##4.删除临时Makefile
Makefile.%: tests/%.c latest | prepare-result
	@/bin/echo -e "NAME = $*\nSRCS = $<\ninclude $${AM_HOME}/Makefile" > $@
	@if make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS); then \
		printf "[%14s] $(COLOR_GREEN)PASS$(COLOR_NONE)\n" $* >> $(RESULT); \
	else \
		printf "[%14s] $(COLOR_RED)***FAIL***$(COLOR_NONE)\n" $* >> $(RESULT); \
	fi
	-@rm -f Makefile.$*
##只在本次 make 需要运行测试时初始化一次结果文件；并行 append 均等待该目标
prepare-result:
	@: > $(RESULT)

##校验已有结果文件；不得依赖 prepare-result，以免检查前截断结果
check-results:
	@python3 scripts/check_results.py --result "$(RESULT)" --expected $(sort $(ALL))

##run目标：先构建所有测试，再输出、校验并删除.result
run: all
	@cat "$(RESULT)"; \
	python3 scripts/check_results.py --result "$(RESULT)" --expected $(sort $(ALL)); \
	rc=$$?; \
	rm -f "$(RESULT)"; \
	exit $$rc

##gdb目标
gdb: all

##清理Makefile.*和build/
clean:
	rm -rf Makefile.* build/

c: all
	@cat "$(RESULT)"; \
	python3 scripts/check_results.py --result "$(RESULT)" --expected $(sort $(ALL)); \
	rc=$$?; \
	rm -f "$(RESULT)"; \
	exit $$rc

##空目标，用于触发依赖链(可能被其他规则用作“总是更新”)
latest:
