#########################################################################
# IMPORTANT NOTES FOR BEGINNERS
# - Tabs vs Spaces: 命令行配方必须以实际的 Tab 字符开头，使用空格会导致 Make 错误。
# - 自动变量: $@ = 目标文件名, $< = 第一个依赖, $^ = 所有依赖（去重）。
#   例: 在规则 `ar rcs $@ $(OBJECTS)` 中，$@ 会变为目标名（如 build/libYOUR_LIBRARY.a）。
# - 变量赋值类型:
#   VAR = value    # 递归展开（lazy），在使用时才展开
#   VAR := value   # 立即展开（immediate）
#   VAR ?= value   # 仅当未被定义时赋值（你的 PREFIX 用法）
#   VAR += value   # 追加
# - 命令行覆盖变量: 你可以通过 `make CFLAGS="-g -O0"` 覆盖 Makefile 中的默认 CFLAGS。
# - 并行构建: 使用 `make -jN`（例如 -j4）加速构建，但确保依赖关系正确以避免竞态。
# - order-only prerequisites: 如果需要只保证某个依赖存在但不希望由其时间戳触发重建，使用 `|`。
#   例: `target: normal-deps | order-only-dir`（确保 order-only-dir 存在，但不作为重建依据）
# - 在 recipe 中要传递字面 $ 给 shell，请使用 $$（Makefile 会先处理 $）。
#   例: 在 Makefile 中写 `echo $$HOME` 会在运行时打印 shell 的 $HOME。
# - 伪目标 (.PHONY): 对于像 `clean`、`tests` 等不产生实际文件的目标，使用 .PHONY 防止文件名冲突。
# - 回滚/恢复: 我们建议在删除或安装前先备份生成文件或使用 DESTDIR 进行临时安装：
#   `make DESTDIR=/tmp/stage install`，便于检查并回滚。
#
# 这些注释只作学习参考，下面是实际的变量和规则定义（不改变原有行为）。
#########################################################################

CFLAGS=-g -O2 -Wall -Wextra -Isrc -rdynamic -DNDEBUG $(OPTFLAGS)
# CFLAGS: 编译器选项
# -g             : 生成调试符号（便于调试）
# -O2            : 优化等级
# -Wall -Wextra  : 开启大多数警告
# -Isrc          : 将 src 目录加入头文件搜索路径
# -rdynamic      : 使符号导出（在生成共享库时有用）
# -DNDEBUG       : 定义 NDEBUG（通常会关闭 assert）
# $(OPTFLAGS)    : 可选的外部附加编译选项（由环境或命令行传入）

LIBS=-ldl $(OPTLIBS)
# LIBS: 链接时需要的库。这里默认链接 libdl（动态加载），
# $(OPTLIBS) 可由外部或命令行传入额外库。

# C compiler (allow overriding from environment)
CC ?= cc

PREFIX?=/usr/local
# PREFIX: 安装前缀（install 目标会用到），可通过 `make PREFIX=/custom/path` 覆盖。

SOURCES=$(wildcard src/**/*.c src/*.c)
# SOURCES: 使用 wildcard 收集 src 下的 C 源文件，支持子目录和顶层 src。
OBJECTS=$(patsubst %.c,%.o,$(SOURCES))
# OBJECTS: 把 SOURCES 中的 .c 文件名替换为对应的 .o（用于链接/打包）

TEST_SRC=$(wildcard tests/*_tests.c)
# TEST_SRC: 收集 tests 目录中约定以 _tests.c 结尾的单元测试源文件
TESTS=$(patsubst %.c,%,$(TEST_SRC))
# TESTS: 将测试源文件名去掉后缀 (.c)，得到可执行或测试条目的名称

TARGET=build/libYOUR_LIBRARY.a
# TARGET: 默认静态库输出路径（名字示例为 libYOUR_LIBRARY.a）
SO_TARGET=$(patsubst %.a,%.so,$(TARGET))
# SO_TARGET: 由静态库名推导出的共享库名（.a -> .so），用于构建共享库

# Specific small example shared object for this exercise
LIBEX_SO=build/libex29.so
LIBEX_SRC=src/libex29.c

# -----------------------------
# 默认目标（all）
# 会构建静态库、共享库（如果需要）并运行单元测试
# -----------------------------
all: $(TARGET) $(SO_TARGET) tests $(LIBEX_SO)

# dev 目标用于开发时快速构建，使用较少优化和更多调试信息
# 例如：make dev
dev: CFLAGS=-g -Wall -Ilsrc -Wall -Wextra $(OPTFLAGS)
dev: all

# 构建静态库时需要启用 -fPIC（位置无关代码）以便后续可以生成共享库
$(TARGET): CFLAGS += -fPIC

# 静态库规则：先确保 build 目录存在并编译对象文件，然后打包为 .a
$(TARGET): build $(OBJECTS)
	ar rcs $@ $(OBJECTS)
	ranlib $@

# 共享库规则：在已有对象文件和静态库的基础上生成 .so（共享库）
$(SO_TARGET): $(TARGET) $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

# Rule to build the small example shared object from its source
$(LIBEX_SO): build $(LIBEX_SRC)
	$(CC) -fPIC -shared -o $@ $(CFLAGS) $(LIBEX_SRC)

# 创建构建目录与二进制目录（不报错）
build:
	@mkdir -p build
	@mkdir -p bin
# -----------------------------
# 单元测试目标
# tests: 会把静态库路径加入 CFLAGS（便于链接测试），然后运行 tests/runtests.sh
# 把 tests 标为 PHONY 以保证总是运行
# -----------------------------
.PHONY: tests
tests: $(TESTS) $(LIBEX_SO)
	sh ./tests/runtests.sh

# Pattern rule: build test executables from tests/*.c
tests/%: tests/%.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

# 在使用 valgrind 进行内存/错误检测时可以用此目标
# 例子：make valgrind
# 它会在调用 make 时为子 make 设置 VALGRIND 环境变量
valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)

# 清理生成文件
# clean: 删除 build 目录、对象文件、测试可执行和覆盖/调试符号等
clean:
	rm -rf build $(OBJECTS) $(TESTS)
	rm -f tests/tests.log
	find . -name "*.gc*" -exec rm {} \;
	rm -rf `find . -name "*.dSYM" -print`

# 安装目标（将库安装到系统前缀下）
# 使用 DESTDIR 用于打包场景，例如：make DESTDIR=/tmp/stage install
install: all
	install -d $(DESTDIR)/$(PREFIX)/lib/
	install $(TARGET) $(DESTDIR)/$(PREFIX)/lib/

# 简单静态代码检查：搜索源码中可能使用危险函数的文件
# BADFUNCS 是一个正则表达式，用来匹配常见的危险函数名
BADFUNCS='[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)'
check:
	@echo Files with potentially dangerous functions.
	@egrep $(BADFUNCS) $(SURCES) || true
