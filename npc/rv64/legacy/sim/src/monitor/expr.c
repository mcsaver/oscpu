/* NPC 表达式求值器 — C 重构版
 * class Parser + std::vector<Token> 改为 struct 数组 + 静态函数族 */
#include "monitor/expr.h"

#include "cpu/cpu.h"
#include "memory/paddr.h"
#include "utils.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if CONFIG_NPC_EXPR

/* ---- 词法 ---- */
#define MAX_TOKENS 128
#define TOKEN_TEXT_MAX 64

enum TokenKind {
  TK_NUMBER = 0,
  TK_HEX_NUMBER,
  TK_REGISTER,
  TK_PLUS,
  TK_MINUS,
  TK_STAR,
  TK_SLASH,
  TK_LPAREN,
  TK_RPAREN,
  TK_EQ,
  TK_NEQ,
  TK_AND,
  TK_OR,
  TK_NOT,
  TK_DEREF,
  TK_NEG,
};

typedef struct {
  int kind;
  char text[TOKEN_TEXT_MAX];
} Token;

static Token g_tokens[MAX_TOKENS];
static int   g_nr_tokens;

static bool is_ident_char(char c) { return isalnum((unsigned char)c) || c == '_'; }

static bool tokenize(const char *expr) {
  g_nr_tokens = 0;
  const char *p = expr;
  while (*p) {
    while (isspace((unsigned char)*p)) ++p;
    if (*p == '\0') break;
    if (g_nr_tokens >= MAX_TOKENS) return false;

    Token *t = &g_tokens[g_nr_tokens];
    memset(t, 0, sizeof(*t));

    switch (*p) {
      case '+': t->kind = TK_PLUS;  t->text[0] = '+'; ++p; break;
      case '-': t->kind = TK_MINUS; t->text[0] = '-'; ++p; break;
      case '*': t->kind = TK_STAR;  t->text[0] = '*'; ++p; break;
      case '/': t->kind = TK_SLASH; t->text[0] = '/'; ++p; break;
      case '(': t->kind = TK_LPAREN; t->text[0] = '('; ++p; break;
      case ')': t->kind = TK_RPAREN; t->text[0] = ')'; ++p; break;
      case '!':
        if (p[1] == '=') { t->kind = TK_NEQ; memcpy(t->text, "!=", 2); p += 2; }
        else { t->kind = TK_NOT; t->text[0] = '!'; ++p; }
        break;
      case '=':
        if (p[1] == '=') { t->kind = TK_EQ; memcpy(t->text, "==", 2); p += 2; }
        else return false;
        break;
      case '&':
        if (p[1] == '&') { t->kind = TK_AND; memcpy(t->text, "&&", 2); p += 2; }
        else return false;
        break;
      case '|':
        if (p[1] == '|') { t->kind = TK_OR; memcpy(t->text, "||", 2); p += 2; }
        else return false;
        break;
      case '$': {
        /* 寄存器访问 $pc, $x0, $ra, ... */
        ++p;
        int len = 0;
        t->text[len++] = '$';
        while (*p && is_ident_char(*p) && len < TOKEN_TEXT_MAX - 1)
          t->text[len++] = *p++;
        t->text[len] = '\0';
        t->kind = TK_REGISTER;
        break;
      }
      default:
        if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
          int len = 0;
          t->text[len++] = *p++; /* '0' */
          t->text[len++] = *p++; /* 'x' */
          while (*p && isxdigit((unsigned char)*p) && len < TOKEN_TEXT_MAX - 1)
            t->text[len++] = *p++;
          t->text[len] = '\0';
          t->kind = TK_HEX_NUMBER;
        } else if (isdigit((unsigned char)*p)) {
          int len = 0;
          while (*p && isdigit((unsigned char)*p) && len < TOKEN_TEXT_MAX - 1)
            t->text[len++] = *p++;
          t->text[len] = '\0';
          t->kind = TK_NUMBER;
        } else {
          return false;
        }
        break;
    }
    ++g_nr_tokens;
  }
  return true;
}

/* 区分一元 *（解引用）和一元 -（取反） */
static void classify_unary(void) {
  for (int i = 0; i < g_nr_tokens; ++i) {
    bool is_unary = (i == 0);
    if (!is_unary) {
      int prev = g_tokens[i - 1].kind;
      is_unary = (prev != TK_NUMBER && prev != TK_HEX_NUMBER && prev != TK_REGISTER && prev != TK_RPAREN);
    }
    if (is_unary && g_tokens[i].kind == TK_STAR) g_tokens[i].kind = TK_DEREF;
    if (is_unary && g_tokens[i].kind == TK_MINUS) g_tokens[i].kind = TK_NEG;
  }
}

/* ---- 递归下降求值 ---- */
static bool g_eval_error;
static int  g_eval_pos;

static npc_word_t eval_expr(void);
static npc_word_t eval_or(void);
static npc_word_t eval_and(void);
static npc_word_t eval_equality(void);
static npc_word_t eval_additive(void);
static npc_word_t eval_multiplicative(void);
static npc_word_t eval_unary(void);
static npc_word_t eval_primary(void);

static int current_kind(void) {
  if (g_eval_pos >= g_nr_tokens) return -1;
  return g_tokens[g_eval_pos].kind;
}

static void advance(void) { if (g_eval_pos < g_nr_tokens) ++g_eval_pos; }

static npc_word_t eval_expr(void) { return eval_or(); }

static npc_word_t eval_or(void) {
  npc_word_t val = eval_and();
  while (!g_eval_error && current_kind() == TK_OR) { advance(); npc_word_t rhs = eval_and(); val = (val || rhs) ? 1 : 0; }
  return val;
}

static npc_word_t eval_and(void) {
  npc_word_t val = eval_equality();
  while (!g_eval_error && current_kind() == TK_AND) { advance(); npc_word_t rhs = eval_equality(); val = (val && rhs) ? 1 : 0; }
  return val;
}

static npc_word_t eval_equality(void) {
  npc_word_t val = eval_additive();
  while (!g_eval_error) {
    int kind = current_kind();
    if (kind == TK_EQ) { advance(); val = (val == eval_additive()) ? 1 : 0; }
    else if (kind == TK_NEQ) { advance(); val = (val != eval_additive()) ? 1 : 0; }
    else break;
  }
  return val;
}

static npc_word_t eval_additive(void) {
  npc_word_t val = eval_multiplicative();
  while (!g_eval_error) {
    int kind = current_kind();
    if (kind == TK_PLUS) { advance(); val += eval_multiplicative(); }
    else if (kind == TK_MINUS) { advance(); val -= eval_multiplicative(); }
    else break;
  }
  return val;
}

static npc_word_t eval_multiplicative(void) {
  npc_word_t val = eval_unary();
  while (!g_eval_error) {
    int kind = current_kind();
    if (kind == TK_STAR) { advance(); val *= eval_unary(); }
    else if (kind == TK_SLASH) {
      advance();
      npc_word_t rhs = eval_unary();
      if (rhs == 0) { g_eval_error = true; return 0; }
      val /= rhs;
    } else break;
  }
  return val;
}

static npc_word_t eval_unary(void) {
  if (g_eval_error) return 0;
  int kind = current_kind();
  if (kind == TK_NEG) { advance(); return (npc_word_t)(-(int64_t)eval_unary()); }
  if (kind == TK_NOT) { advance(); return eval_unary() == 0 ? 1u : 0u; }
  if (kind == TK_DEREF) {
    advance();
    npc_word_t addr = eval_unary();
    npc_word_t val = 0;
    if (!npc_paddr_read(addr, &val, NPC_BUS_LOAD)) {
      g_eval_error = true; return 0;
    }
    return val;
  }
  return eval_primary();
}

static npc_word_t eval_primary(void) {
  if (g_eval_error) return 0;
  int kind = current_kind();

  if (kind == TK_NUMBER) {
    npc_word_t val = (npc_word_t)strtoull(g_tokens[g_eval_pos].text, NULL, 10);
    advance(); return val;
  }
  if (kind == TK_HEX_NUMBER) {
    npc_word_t val = (npc_word_t)strtoull(g_tokens[g_eval_pos].text, NULL, 16);
    advance(); return val;
  }
  if (kind == TK_REGISTER) {
    /* 跳过 '$' 取寄存器名 */
    const char *reg_name = g_tokens[g_eval_pos].text + 1;
    advance();
    npc_word_t val = 0;
    if (!npc_isa_reg_str2val(reg_name, &val)) {
      g_eval_error = true; return 0;
    }
    return val;
  }
  if (kind == TK_LPAREN) {
    advance();
    npc_word_t val = eval_expr();
    if (current_kind() != TK_RPAREN) { g_eval_error = true; return 0; }
    advance();
    return val;
  }

  g_eval_error = true;
  return 0;
}

/* ---- 公共 API ---- */

void npc_init_expr(void) {
  /* 目前无需初始化，保留接口 */
}

bool npc_expr(const char *text, npc_word_t *result) {
  if (!text || !result) return false;

  if (!tokenize(text)) return false;
  classify_unary();

  g_eval_error = false;
  g_eval_pos = 0;
  npc_word_t val = eval_expr();

  if (g_eval_error || g_eval_pos != g_nr_tokens) return false;
  *result = val;
  return true;
}

#else /* !CONFIG_NPC_EXPR */

void npc_init_expr(void) {}
bool npc_expr(const char *text, npc_word_t *result) {
  (void)text; (void)result;
  return false;
}

#endif
