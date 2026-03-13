/*
 * 编译指令：
 * 1. verilator --cc --exe --build --trace --trace-fst -j 0 -Wall key.v tb.cpp
 * 2. ./obj_dir/Vkey
 * 3. gtkwave build/logs/cpu_waves.fst
 *
 * 这将生成仿真可执行文件并运行，波形文件保存在 build/logs/cpu_waves.fst，然后用 gtkwave 打开查看波形
 */

//与verilator无关的一些头文件
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <string>
#include <limits.h>

//使用verilater必须include
#include "Vkey.h" //仿真模型的头文件，由top.v生成，如果顶层文件名更改则也需要更改
#include <verilated.h>

#define CONFIG_FST_WAVE_TRACE 1


static volatile bool stop_requested = false;
static void sigint_handler(int) { stop_requested = true;}

// contextp用来保存仿真的时间
VerilatedContext *contextp = new VerilatedContext;

// 构建一个名为top的仿真模型
Vkey *top = new Vkey{contextp};

//如果生成FST格式的wave
#if CONFIG_FST_WAVE_TRACE
#include "verilated_fst_c.h"            //波形文件所需的头文件
VerilatedFstC *tfp = new VerilatedFstC; // 创建一个波形文件指针
#endif

//仿真的过程
int main(int argc, char **argv)
{
    signal(SIGINT, sigint_handler);

    char cwd[PATH_MAX];
    if (!getcwd(cwd, sizeof(cwd))) {
        perror("getcwd");
        return 1;
    }
    std::string fst_path = std::string(cwd) + "/build/logs/cpu_waves.fst";

    Verilated::mkdir("build/logs");
    contextp->commandArgs(argc,argv);

#if CONFIG_FST_WAVE_TRACE
    contextp->traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open(fst_path.c_str());
#endif

    const vluint64_t MAX_TIME = 10000;
    top->clk = 0;
    top->rst = 0;

    while (!contextp->gotFinish() && !stop_requested)
    {
        int a = rand() & 1;
        int b = rand() & 1;
        top->a = a;
        top->b = b;
        top->clk = !top->clk;
        top->eval();
        printf("time=%llu a = %d, b = %d, f = %d\n",
        (unsigned long long)contextp->time(), a, b, top->f);

        contextp->timeInc(1);
    #if CONFIG_FST_WAVE_TRACE
            tfp->dump(contextp->time());
    #endif

            if (contextp->time() >= MAX_TIME) {
                Verilated::gotFinish(true);
            }
    }
    
    #if CONFIG_FST_WAVE_TRACE
        if (tfp) tfp->close();
    #endif

    top->final();
    delete top;
    top = nullptr;
    delete contextp;
    contextp = nullptr;
    return 0;
}
// 结束文件，之前有重复的清理代码已移除