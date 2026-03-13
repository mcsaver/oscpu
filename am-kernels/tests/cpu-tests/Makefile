.PHONY: all run gdb clean latest $(ALL)

##结果文件：先清空结果文件，用于汇总各测试的PASS/FAIL
RESULT = .result
$(shell > $(RESULT))

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
Makefile.%: tests/%.c latest
	@/bin/echo -e "NAME = $*\nSRCS = $<\ninclude $${AM_HOME}/Makefile" > $@
	@if make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS); then \
		printf "[%14s] $(COLOR_GREEN)PASS$(COLOR_NONE)\n" $* >> $(RESULT); \
	else \
		printf "[%14s] $(COLOR_RED)***FAIL***$(COLOR_NONE)\n" $* >> $(RESULT); \
	fi
	-@rm -f Makefile.$*

##run目标：先构建所有测试，再输出.result并删除它
run: all
	@cat $(RESULT)
	@rm $(RESULT)

##gdb目标
gdb: all

##清理Makefile.*和build/
clean:
	rm -rf Makefile.* build/

c: all
	@cat $(RESULT)
	@rm $(RESULT)

##空目标，用于触发依赖链(可能被其他规则用作“总是更新”)
latest:
