#include "monitor/expr.h"

#include "cpu/cpu.h"
#include "memory/paddr.h"

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

namespace npc {

namespace {

enum class TokenKind {
  kNumber,
  kRegister,
  kPlus,
  kMinus,
  kMul,
  kDiv,
  kEq,
  kNeq,
  kAnd,
  kOr,
  kNot,
  kLParen,
  kRParen,
  kEnd,
};

struct Token {
  TokenKind kind = TokenKind::kEnd;
  std::string text;
  uint32_t value = 0;
};

bool parse_number(const std::string &text, uint32_t *value) {
  if (value == nullptr) {
    return false;
  }

  char *end = nullptr;
  const unsigned long parsed = std::strtoul(text.c_str(), &end, 0);
  if (end == nullptr || *end != '\0') {
    return false;
  }
  *value = static_cast<uint32_t>(parsed);
  return true;
}

bool tokenize(const std::string &text, std::vector<Token> *tokens) {
  if (tokens == nullptr) {
    return false;
  }

  tokens->clear();
  std::size_t index = 0;
  while (index < text.size()) {
    const char ch = text[index];
    if (std::isspace(static_cast<unsigned char>(ch)) != 0) {
      ++index;
      continue;
    }

    if (ch == '(') {
      tokens->push_back({TokenKind::kLParen, "(", 0});
      ++index;
      continue;
    }
    if (ch == ')') {
      tokens->push_back({TokenKind::kRParen, ")", 0});
      ++index;
      continue;
    }
    if (ch == '+') {
      tokens->push_back({TokenKind::kPlus, "+", 0});
      ++index;
      continue;
    }
    if (ch == '-') {
      tokens->push_back({TokenKind::kMinus, "-", 0});
      ++index;
      continue;
    }
    if (ch == '*') {
      tokens->push_back({TokenKind::kMul, "*", 0});
      ++index;
      continue;
    }
    if (ch == '/') {
      tokens->push_back({TokenKind::kDiv, "/", 0});
      ++index;
      continue;
    }
    if (ch == '!') {
      if (index + 1 < text.size() && text[index + 1] == '=') {
        tokens->push_back({TokenKind::kNeq, "!=", 0});
        index += 2;
      } else {
        tokens->push_back({TokenKind::kNot, "!", 0});
        ++index;
      }
      continue;
    }
    if (ch == '=') {
      if (index + 1 >= text.size() || text[index + 1] != '=') {
        return false;
      }
      tokens->push_back({TokenKind::kEq, "==", 0});
      index += 2;
      continue;
    }
    if (ch == '&') {
      if (index + 1 >= text.size() || text[index + 1] != '&') {
        return false;
      }
      tokens->push_back({TokenKind::kAnd, "&&", 0});
      index += 2;
      continue;
    }
    if (ch == '|') {
      if (index + 1 >= text.size() || text[index + 1] != '|') {
        return false;
      }
      tokens->push_back({TokenKind::kOr, "||", 0});
      index += 2;
      continue;
    }
    if (ch == '$') {
      const std::size_t begin = ++index;
      while (index < text.size() && (std::isalnum(static_cast<unsigned char>(text[index])) != 0 || text[index] == '_')) {
        ++index;
      }
      if (begin == index) {
        return false;
      }
      tokens->push_back({TokenKind::kRegister, text.substr(begin, index - begin), 0});
      continue;
    }
    if (std::isdigit(static_cast<unsigned char>(ch)) != 0) {
      const std::size_t begin = index;
      ++index;
      while (index < text.size() && (std::isalnum(static_cast<unsigned char>(text[index])) != 0 || text[index] == 'x' || text[index] == 'X')) {
        ++index;
      }
      Token token;
      token.kind = TokenKind::kNumber;
      token.text = text.substr(begin, index - begin);
      if (!parse_number(token.text, &token.value)) {
        return false;
      }
      tokens->push_back(token);
      continue;
    }

    return false;
  }

  tokens->push_back({TokenKind::kEnd, "", 0});
  return true;
}

class Parser {
 public:
  explicit Parser(const std::vector<Token> &tokens) : tokens_(tokens) {
  }

  bool Parse(uint32_t *result) {
    if (result == nullptr) {
      return false;
    }
    uint32_t value = 0;
    if (!ParseLogicalOr(&value)) {
      return false;
    }
    if (Current().kind != TokenKind::kEnd) {
      return false;
    }
    *result = value;
    return true;
  }

 private:
  const Token &Current() const {
    return tokens_[index_];
  }

  const Token &Advance() {
    return tokens_[index_++];
  }

  bool ParseLogicalOr(uint32_t *value) {
    if (!ParseLogicalAnd(value)) {
      return false;
    }
    while (Current().kind == TokenKind::kOr) {
      Advance();
      uint32_t rhs = 0;
      if (!ParseLogicalAnd(&rhs)) {
        return false;
      }
      *value = ((*value != 0) || (rhs != 0)) ? 1u : 0u;
    }
    return true;
  }

  bool ParseLogicalAnd(uint32_t *value) {
    if (!ParseEquality(value)) {
      return false;
    }
    while (Current().kind == TokenKind::kAnd) {
      Advance();
      uint32_t rhs = 0;
      if (!ParseEquality(&rhs)) {
        return false;
      }
      *value = ((*value != 0) && (rhs != 0)) ? 1u : 0u;
    }
    return true;
  }

  bool ParseEquality(uint32_t *value) {
    if (!ParseAdditive(value)) {
      return false;
    }
    while (Current().kind == TokenKind::kEq || Current().kind == TokenKind::kNeq) {
      const TokenKind op = Advance().kind;
      uint32_t rhs = 0;
      if (!ParseAdditive(&rhs)) {
        return false;
      }
      *value = (op == TokenKind::kEq) ? (*value == rhs ? 1u : 0u) : (*value != rhs ? 1u : 0u);
    }
    return true;
  }

  bool ParseAdditive(uint32_t *value) {
    if (!ParseMultiplicative(value)) {
      return false;
    }
    while (Current().kind == TokenKind::kPlus || Current().kind == TokenKind::kMinus) {
      const TokenKind op = Advance().kind;
      uint32_t rhs = 0;
      if (!ParseMultiplicative(&rhs)) {
        return false;
      }
      *value = (op == TokenKind::kPlus) ? (*value + rhs) : (*value - rhs);
    }
    return true;
  }

  bool ParseMultiplicative(uint32_t *value) {
    if (!ParseUnary(value)) {
      return false;
    }
    while (Current().kind == TokenKind::kMul || Current().kind == TokenKind::kDiv) {
      const TokenKind op = Advance().kind;
      uint32_t rhs = 0;
      if (!ParseUnary(&rhs)) {
        return false;
      }
      if (op == TokenKind::kDiv) {
        if (rhs == 0) {
          return false;
        }
        *value /= rhs;
      } else {
        *value *= rhs;
      }
    }
    return true;
  }

  bool ParseUnary(uint32_t *value) {
    if (Current().kind == TokenKind::kMinus) {
      Advance();
      uint32_t rhs = 0;
      if (!ParseUnary(&rhs)) {
        return false;
      }
      *value = static_cast<uint32_t>(-static_cast<int32_t>(rhs));
      return true;
    }
    if (Current().kind == TokenKind::kNot) {
      Advance();
      uint32_t rhs = 0;
      if (!ParseUnary(&rhs)) {
        return false;
      }
      *value = (rhs == 0) ? 1u : 0u;
      return true;
    }
    if (Current().kind == TokenKind::kMul) {
      Advance();
      uint32_t addr = 0;
      if (!ParseUnary(&addr)) {
        return false;
      }
      return paddr_read(addr, value);
    }
    return ParsePrimary(value);
  }

  bool ParsePrimary(uint32_t *value) {
    if (Current().kind == TokenKind::kNumber) {
      *value = Advance().value;
      return true;
    }
    if (Current().kind == TokenKind::kRegister) {
      const std::string reg_name = Advance().text;
      return isa_reg_str2val(reg_name.c_str(), value);
    }
    if (Current().kind == TokenKind::kLParen) {
      Advance();
      if (!ParseLogicalOr(value)) {
        return false;
      }
      if (Current().kind != TokenKind::kRParen) {
        return false;
      }
      Advance();
      return true;
    }
    return false;
  }

  const std::vector<Token> &tokens_;
  std::size_t index_ = 0;
};

}  // namespace

void init_expr() {
  // 这里保留显式初始化入口，对齐 NEMU 的 monitor 子系统边界；当前手写解析器无需额外运行期状态。
}

bool expr(const std::string &text, uint32_t *result) {
#if !CONFIG_NPC_EXPR
  (void)text;
  (void)result;
  return false;
#else
  std::vector<Token> tokens;
  if (!tokenize(text, &tokens)) {
    return false;
  }
  Parser parser(tokens);
  return parser.Parse(result);
#endif
}

}  // namespace npc