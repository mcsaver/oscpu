# Incident V12 dispatch log

- 输入：用户提供的通用内容不可显示 UI notice。
- 证据保存：`evidence/ui-notice.png`，SHA-256
  `7977cc0796211fc7c714e3d67518c76f9858627b4ee4d602dbaa002d75a77996`。
- 可判定边界：截图不提供逐词根因；只记录“字段级硬件上下文不足”这一可操作工程假设。
- 已固化路径：`.github/skills/prepare-rtl-task-contract/SKILL.md`、
  `.github/instructions/rtl-agent-task-contract.instructions.md`、
  `npc/rv64/design/arch/rv64-hardware-wording-profile.md` 和 canonical renderer。
- 能力边界：源码探索、实现、验证、PPA、断言、负向 RTL 变体及未知项出口保持不变。
