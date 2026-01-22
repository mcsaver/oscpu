/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
//用于表达式求值

#include <isa.h>
//#include "local-include/reg.h"
/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include "memory/paddr.h"

//定义tokens大小
#define BUF_SIZ 1024

bool enable_expr_log = true;

// tokens 类型定义：
// - 256 起是为了避免和 ASCII 字符冲突（例如 '+' '-' '*' '/' '(' ')' 直接用字符本身做 type）
// - 这里把“复杂/多字符 token”（如 ==、十进制数字、一元负号）单独用枚举值表示
enum {
  //从256开始是为了避免和ASCII字符冲突
  TK_NOTYPE = 256,
  TK_EQ = 257,
  TK_DECIMAL = 258,
  TK_NEG = 259,
  DEREF = 260,
  TK_NEQ,
  TK_HEX,
  TK_DOUAM,
/*   TK_REG_0,   // $0
  TK_REG_RA,  // $ra
  TK_REG_SP,  // $sp
  TK_REG_GP,  // $gp
  TK_REG_TP,  // $tp
  TK_REG_T0,  // $t0
  TK_REG_T1,  // $t1
  TK_REG_T2,  // $t2
  TK_REG_S0,  // $s0
  TK_REG_S1,  // $s1
  TK_REG_A0,  // $a0
  TK_REG_A1,  // $a1
  TK_REG_A2,  // $a2
  TK_REG_A3,  // $a3
  TK_REG_A4,  // $a4
  TK_REG_A5,  // $a5
  TK_REG_A6,  // $a6
  TK_REG_A7,  // $a7
  TK_REG_S2,  // $s2
  TK_REG_S3,  // $s3
  TK_REG_S4,  // $s4
  TK_REG_S5,  // $s5
  TK_REG_S6,  // $s6
  TK_REG_S7,  // $s7
  TK_REG_S8,  // $s8
  TK_REG_S9,  // $s9
  TK_REG_S10, // $s10
  TK_REG_S11, // $s11
  TK_REG_T3,  // $t3
  TK_REG_T4,  // $t4
  TK_REG_T5,  // $t5
  TK_REG_T6,  // $t6 */
  TK_D
  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {
  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */
// 词法规则表：用 POSIX regex 定义“如何匹配 token”以及“匹配后 token 的类型”
// 注意：规则是按顺序尝试匹配的，越靠前优先级越高；因此多字符 token 要放在前面（例如 "==" 必须在 "=" 之前）
// 本实验先支持：十进制整数、+ - * /、括号、空格
  {"0[xX][0-9a-fA-F]+", TK_HEX}, // 新增：匹配16进制数
/*   {"\\$0", TK_REG_0},
  {"\\$ra", TK_REG_RA},
  {"\\$sp", TK_REG_SP},
  {"\\$gp", TK_REG_GP},
  {"\\$tp", TK_REG_TP},
  {"\\$t0", TK_REG_T0},
  {"\\$t1", TK_REG_T1},
  {"\\$t2", TK_REG_T2},
  {"\\$s0", TK_REG_S0},
  {"\\$s1", TK_REG_S1},
  {"\\$a0", TK_REG_A0},
  {"\\$a1", TK_REG_A1},
  {"\\$a2", TK_REG_A2},
  {"\\$a3", TK_REG_A3},
  {"\\$a4", TK_REG_A4},
  {"\\$a5", TK_REG_A5},
  {"\\$a6", TK_REG_A6},
  {"\\$a7", TK_REG_A7},
  {"\\$s2", TK_REG_S2},
  {"\\$s3", TK_REG_S3},
  {"\\$s4", TK_REG_S4},
  {"\\$s5", TK_REG_S5},
  {"\\$s6", TK_REG_S6},
  {"\\$s7", TK_REG_S7},
  {"\\$s8", TK_REG_S8},
  {"\\$s9", TK_REG_S9},
  {"\\$s10", TK_REG_S10},
  {"\\$s11", TK_REG_S11},
  {"\\$t3", TK_REG_T3},
  {"\\$t4", TK_REG_T4},
  {"\\$t5", TK_REG_T5},
  {"\\$t6", TK_REG_T6}, */
  {"\\$[a-z0-9]+", TK_D}, 
  {"&&", TK_DOUAM},
  {" +", TK_NOTYPE},    // spaces
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},       // not equal
  //{"0[xX][0-9a-fA-F]+", TK_HEX}, // 新增：匹配16进制数
  {"[0-9]+", TK_DECIMAL}, // decimal number
 //{"0[xX][0-9a-fA-F]+", TK_HEX}, // 新增：匹配16进制数
  {"\\+", '+'},         // plus
  {"\\-", '-'},         // minus
  {"\\*", '*'},         // multiply
  {"/", '/'},          // divide
  {"\\(", '('},       // left parenthesis
  {"\\)", ')'},        // right parenthesis
};

//NR_REGEX：规则数量
#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
//re[]保存每条规则编译后的正则对象
//只编译一次，后续反复调用make_token()时直接regexec()，避免反复编译带来的性能浪费
//编译失败会panic()直接终止
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  // 将 rules[] 中的每条正则提前编译到 re[]，避免 make_token() 每次都重复编译带来的开销
  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

//tokes[]：保存词法分析得到的token序列
//nr_token：当前token数
//这里token数和token文本都有硬编码上限：最多32个token，每个token的字面串最多31个字符（留一个\0）
typedef struct token {
  int type;
  // token 的字面量字符串（主要用于数字 token 的 atoi，以及调试输出）。
  // 这里给了较大的 BUF_SIZ 上限，避免随机测试生成的长表达式导致 token 文本被截断。
  char str[BUF_SIZ];
} Token;

static Token tokens[BUF_SIZ] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

// eval() 过程中用于“软失败”的标志：避免除 0 等情况直接触发宿主机 SIGFPE
//eval_success为eval() 过程中用于“软失败”的标志，避免assert直接退出nemu
// 背景：gen-expr 会随机生成包含除法的表达式，可能出现除 0。
// 如果 NEMU 直接执行 `a / 0`，会触发宿主机 SIGFPE（Floating point exception）导致 NEMU 进程崩溃。
// 解决：在 eval() 检测到不合法/不支持的情况时，置 eval_success=false，并返回一个占位值 0。
// expr() 最终把 eval_success 反馈到 *success，让上层（例如 `p test`）把该用例记为失败/跳过。
static bool eval_success = true;

//词法分析主循环：
//从position从0开始，表示扫描到字符串e的哪个位置
//外层while(e[position] != '\0')：直到字符串结束
//内层for(i=0;i<NR;i++)：尝试所有规则，看哪个能在当前位置匹配
// make_token(): 把输入字符串 e 做词法分析，生成 tokens[0..nr_token-1]
// 解析失败返回 false；成功返回 true
//把输入字符串分割成一个个token，每个token有自己的类型(type)和原始字符串(str)
//后续再eval递归求值的时候，遇到数字token会用atoi把str转换成int
static bool make_token(char *e) {
  int position = 0;
  int i;
  //regexct结构体用于保存匹配结果
  //pmatch.rm_so：匹配子串在e+position中的起始位置（相对于e+position的偏移）
  //pmatch.rm_eo：匹配子串在e+position中的结束位置
  regmatch_t pmatch;

  nr_token = 0;

  // position 表示当前扫描到 e 的哪个位置
  while (e[position] != '\0') {
    /* Try all rules one by one. */
    // 依次尝试所有规则：要求匹配必须从当前位置开始（pmatch.rm_so == 0）
    for (i = 0; i < NR_REGEX; i ++) {
      //regexec(i)：用第i条规则的正则对象在e+position这段子串上执行匹配
      //如果匹配成功，regexec返回0，并把匹配结果保存在pmatch中
      //匹配的子串的起止位置写入pmatch.rm_so和pmatch.rm_eo
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        //关键判断，regexec在e+position这段子串上执行匹配，pmatch.rm_so == 0 强制要求匹配必须从字串起始位置开始
        //否则会出现跳着匹配导致无法推进position的问题
        //成功匹配后
        //substr_len是本次匹配到的token文本长度
        //position前进，继续扫描后面的内容
        //Log(...)只是调试输出：打印命中规则、位置、长度、匹配到的文本
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;
        
        // 逐 token 打印 Log 会在批量对拍（`p test`）时产生海量输出，严重影响阅读与性能
        // 如需调试词法匹配过程，可以临时取消注释下面这段 Log
        
        if (enable_expr_log) {
          Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);
        }
        // 消耗掉本次匹配到的 token 文本
        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        // 将 token 记录到 tokens[]
        // - TK_NOTYPE（空白）直接跳过
        // - 其他 token：记录 type，并把字面量拷贝到 tokens[nr_token].str（方便后续 atoi/调试）
        switch (rules[i].token_type) {
          case TK_NOTYPE://跳过空格
            break;
          case TK_HEX://16进制
            if (nr_token >= BUF_SIZ)
            {
              printf("too many tokens\n");
              return false;
            }
            tokens[nr_token].type =TK_HEX;
            if (substr_len >= BUF_SIZ)
            {
              printf("token too long\n");
              return false;
            }

            // 注意 strncpy 不会自动补 '\0'，这里手动补齐
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token].str[substr_len] = '\0';//加上字符串结尾符
            nr_token ++;
              break;
          default://其他token都记录下来
            if (nr_token >= BUF_SIZ)
            {
              printf("too many tokens\n");
              return false;
            }
            tokens[nr_token].type = rules[i].token_type;
            if (substr_len >= BUF_SIZ)
            {
              printf("token too long\n");
              return false;
            }

            // 注意 strncpy 不会自动补 '\0'，这里手动补齐
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token].str[substr_len] = '\0';//加上字符串结尾符
            nr_token ++;
            break; 
        }
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  // 区分一元负号与二元减号：
  // - 词法阶段无法仅靠 regex 区分（两者都是 '-'）
  // - 这里做一次 token 序列后处理：
  //   若 '-' 出现在表达式开头，或出现在 ( / 运算符 之后，则把它标记为 TK_NEG（一元负号）
  for (int i = 0; i < nr_token; i++) {
    if (tokens[i].type != '-') continue;
    if (i == 0) {
      tokens[i].type = TK_NEG;
      continue;
    }

    int prev = tokens[i - 1].type;
    // 这些 token 后面出现 '-'，通常表示“取负”而不是“相减”
    if (prev == '(' || prev == '+' || prev == '-' || prev == '*' || prev == '/' || prev == TK_EQ
    || prev == TK_NEQ || prev == TK_D) {
      tokens[i].type = TK_NEG;
    }
  }

  return true;
}

int get_priority(int token_type)
{
  // 运算符优先级：数值越小优先级越低（越应该作为“主运算符”先被分裂）
  // 例如：1+2*3 的主运算符是 '+'（优先级更低）
  switch (token_type)
  {
    case TK_DOUAM: return -1;
    case TK_EQ: return 0;
    case TK_NEQ: return 0;
    case '+': return 1;
    case '-': return 1;
    case '*': return 2;
    case '/': return 2;
    case TK_NEG: return 3;
    case DEREF: return 4;
    case TK_D: return 5;
    default: return 100;
  }
}

int check_parentheses(int p, int q)
{
  // 判断 tokens[p..q] 是否被“一对最外层括号”完整包裹
  // 返回 true 的条件：
  // 1) tokens[p] == '(' 且 tokens[q] == ')'
  // 2) 中间括号能正确配对，并且不会在中途提前闭合最外层括号
  if (tokens[p].type != '(' || tokens[q].type != ')')
    return false;

  int bracket_level = 0;
  for (int i = p + 1; i < q; i++)
  {
    if (tokens[i].type == '(')
      bracket_level ++;
    else if (tokens[i].type == ')')
    {
      if (bracket_level == 0)
        return false;
      bracket_level --;
    }
  }

  return bracket_level == 0;
}

//递归下降解析求值表达式
//eval(p,q)：计算tokens[p..q]表示的子表达式的值
static uint32_t eval(int p, int q) {
  // 递归下降求值：计算 tokens[p..q] 这段 token 表示的表达式的值
  if (p > q) {
    /* Bad expression */
    //不要 assert/panic 直接炸掉 NEMU，而是“软失败”交给上层处理
    eval_success = false;
    return 0;
  }
  else if (p == q) {
    /* Single token.
     * For now this token should be a number.
     * Return the value of the number.
     */
    
    if (tokens[p].type == TK_DECIMAL)
    {
      return (uint32_t)atoi(tokens[p].str);
    }
    else if(tokens[p].type == TK_HEX)
    {
      return (uint32_t)strtoul(tokens[p].str, NULL, 16);
    }
    
    else if (tokens[p].type == TK_D)
    {
        // 取寄存器名字符串
        //assert(op == p);
        char *pc_char = "$pc";
        //strcmp(tokens[p].str, pc_char)
        if (strcmp(tokens[p].str, pc_char) == 0)
        {
              return cpu.pc;
        }
        else {
        word_t der_reg = isa_reg_str2val(&tokens[p].str[1], &eval_success);
        //printf(FMT_WORD"\n",der_reg );
        //printf("%s\n", &tokens[p].str[1]);
        return der_reg;
              }
    }
  }
  
  else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(p + 1, q - 1);
  }
  else {
    int op = -1;
    int op_type = -1;//主运算符下的子运算的主运算符
    int min_pri = 100;
    int bracket_level = 0;
    // 寻找“主运算符”位置 op：
    // - 只在最外层（bracket_level==0）挑选运算符，跳过括号内的运算符
    // - 这里按优先级最小（最低优先级）作为主运算符
    // - 从右往左扫描可以更自然地处理左结合（同级运算符优先取更靠右的作为分裂点）
    for (int i = q; i >= p; i--) {
      if (tokens[i].type == ')') bracket_level++;
      else if (tokens[i].type == '(') bracket_level--;
      else if (bracket_level == 0 &&
        (tokens[i].type == '+' ||
         tokens[i].type == '-' ||
         tokens[i].type == '*' ||
         tokens[i].type == '/' ||
         tokens[i].type == TK_NEG ||
         tokens[i].type == DEREF ||
         tokens[i].type == TK_EQ ||
         tokens[i].type == TK_NEQ ||
         tokens[i].type == TK_DOUAM ||
         tokens[i].type == TK_D)) {
        int pri = get_priority(tokens[i].type);
        if (pri < min_pri ) {
          min_pri = pri;
          op = i;
          op_type = tokens[i].type;
        }
      }
    }

    if (op == -1) {
      // [新增] 没找到主运算符：属于不合法表达式（例如括号不配对、token 序列异常等）
      eval_success = false;
      return 0;
    }

    if (op_type == DEREF) {
      assert(op == p);
/*       // 判断 tokens[op + 1] 是否为寄存器类型
      if (tokens[op + 1].type >= TK_REG_0 && tokens[op + 1].type <= TK_REG_T6) {
        // 取寄存器名字符串
        word_t der_reg = isa_reg_str2val(&tokens[op + 1].str[1], &eval_success);
        //printf(FMT_WORD"\n",der_reg );
        //printf("%s\n", &tokens[op + 1].str[1]);
        return der_reg;
      } else {
        paddr_t ad = (uint32_t)eval(op + 1, q);
        return (uint32_t)paddr_read(ad, 4);
      } */
        paddr_t ad = (uint32_t)eval(op + 1, q);
        return (uint32_t)paddr_read(ad, 4);
    }

    if (op_type == TK_D)
    {
        // 取寄存器名字符串
        //assert(op == p);
        word_t der_reg = isa_reg_str2val(&tokens[op].str[1], &eval_success);
        printf(FMT_WORD"\n",der_reg );
        printf("%s\n", &tokens[op].str[1]);
        return der_reg;
    }
    

/*     if (op_type == TK_NEG) {
      // 一元负号：形式应当是 - <expr>，因此 TK_NEG 必须出现在当前子表达式开头
      assert(op == p);
      int32_t v = (int32_t)eval(op + 1, q);//先把后面的值算出来
      int64_t r = -(int64_t)v;
      return (uint32_t)(int32_t)r;
    } */

    // 二元运算符：把表达式按主运算符切成左右两边递归求值
    uint32_t val1 = eval(p, op - 1);
    uint32_t val2 = eval(op + 1, q);

    switch (op_type) {
      case '+': return val1 + val2;
      case '-': return val1 - val2;
      case '*': return val1 * val2;
      case '/': {
        // gen-expr 生成的 C 程序中：表达式按“有符号 int”计算，然后赋给 unsigned
        // 因此这里需要按 int32_t 语义做除法（尤其是负数参与除法时）。
        if (val2 == 0) {
          //除 0：标记失败，避免触发宿主机 SIGFPE
          eval_success = false;
          return 0;
        }
        int32_t a = (int32_t)val1;
        int32_t b = (int32_t)val2;
        int64_t qv = (int64_t)a / (int64_t)b; // 避免 int32_t 的潜在 UB
        return (uint32_t)(int32_t)qv;
      }
      case TK_EQ: return val1 == val2;
      case TK_NEQ: return val1 != val2;
      case TK_DOUAM: return val1 & val2;
      default: assert(0);
    }
  }
  return 0;
}

//指针解引用前面可能出现的符号
static int is_op(int type) {
  return type == '+' || type == '-' || type == '*' || type == '/' ||
          type == TK_EQ || type == TK_NEG || type == '(' || type == DEREF
          || type == TK_NEQ || type == TK_DOUAM;
}


//对外接口
//expr()是给SDB调用的入口，返回word_t（由isa.h定义，通常是uint32_t或uint64_t）
//success：输出参数，表示表达式求值是否成功
word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  for (int i = 0; i < nr_token; i ++) {
  if (tokens[i].type == '*' && (i == 0 || is_op(tokens[i - 1].type) ) ) {
    tokens[i].type = DEREF;
  }
}

  /* TODO: Insert codes to evaluate the expression. */
  eval_success = true; // 软失败标志的初始化
  word_t v = (word_t)eval(0, nr_token - 1);
  *success = eval_success; // 把 eval() 的软失败状态回传给调用者
  return v;
}
