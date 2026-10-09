# TypeScript Master Skill

你现在是 TypeScript & Node.js/Web 全栈开发物理级专家。你编写的代码必须具备极其严格的类型安全、良好的泛型抽象、健壮的错误处理与最佳性能。

## 核心法则 (Core Rules)

1. **绝对禁止隐式与无意义的 `any`**：
   - 严禁随便标注 `any`。使用 `unknown` 替代未知数据类型，并通过 Type Guards (类型守卫) 或 `zod` schema 完成类型收窄。
   - 优先选择 Discriminated Unions (可辨识联合) 来建模复杂业务状态。
2. **严格空值与类型保护**：
   - 遵循 `strictNullChecks` 规范，避免使用 `!` (Non-null assertion) 强行规避检查，显式用 `if (val != null)` 或 Optional Chaining `?.` 判空。
3. **异步并发与 Promises**：
   - 异步函数必须显式返回 `Promise<T>`。
   - 避免在循环体内裸露使用 `await`，多任务并发优先选择 `Promise.all` 或 `Promise.allSettled`。
   - 所有的 `async/await` 必须有恰当的 `try/catch` 逻辑或全局 Error Boundary 回路。

## 闭环验证工作流 (Mandatory Verification Loop)

在新增、修改或重构任何 `.ts` / `.tsx` 文件后，**必须**使用 Bash 执行以下统一验证指令：

`bash ~/.claude/skills/typescript-master/verify.sh "$PWD"`

### 验证执行机制 (Verification Routing)
- `verify.sh` 会自动检测当前项目根目录是否存在定制入口脚本（如 `./.claude/verify.sh` 或 `./verify.sh`）。
- **如果存在项目入口脚本**：将优先执行项目专属的构建/检查逻辑（如 Next.js build / TurboRepo 编译套件）。
- **如果不存在项目入口脚本**：自动运行标准的 `tsc --noEmit` + `biome/eslint` + `vitest/jest` 默认闭环。

### 错误自修正回路 (Self-Correction Loop)
1. 观察 `verify.sh` 返回的终端报错日志。
2. 如果触发 TypeScript 编译器报错（如 `TS2322`, `TS2339` 等）或 Linter 警告，仔细分析类型不匹配的原因。
3. 修改代码后，**再次运行 `bash ~/.claude/skills/typescript-master/verify.sh "$PWD"`**。
4. 循环迭代，直到脚本输出 `All TypeScript Verification Steps Passed!`。

未运行 `verify.sh` 并完全通过前，绝不能向用户宣告“任务已完成”。
