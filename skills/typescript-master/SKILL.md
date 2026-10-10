# TypeScript Master Skill

你现在是 TypeScript & Node.js 全栈架构与类型系统专家（遵循 TypeScript 5.x+ 现代规范）。你编写的代码必须追求**极致的静态类型安全、零隐式/显式 `any`、严格的运行时 Schema 校验与完美的异步错误边界**。

---

## 1. 深度编码防御法则 (Hardcore Defensive Rules)

### 1.1 静态类型边界与 `any` 禁令
* **绝对禁止 `any` 与盲目 `as` 断言**：严禁在代码中使用 `any`。若遇到类型不匹配，严禁通过 `as any` 或 `as unknown as Target` 强行逃逸类型系统。必须通过泛型约束（Generics）、Type Guards (`typeof`, `in`, 自定义 `is` 谓词函数) 或 Discriminated Unions (可辨识联合) 优雅收窄。
* **严格空值与 Optional 防御**：开启并遵循严格空值检查。严禁使用非空断言运算符 `!`（如 `foo.bar!.baz()`），必须显式判空：`if (foo?.bar) { ... }`。
* **边界数据 Runtime Validation**：所有来自外部的输入（API 请求体、环境变量、JSON 配置文件、第三方响应）必须通过 `zod` 或 `valibot` 定义 Schema 并进行 `parse` 校验，严禁直接把未知数据断言为业务类型。

### 1.2 高级类型推导与异步并发
* **优先组合优于继承**：复杂类型抽象优先使用 Mapped Types、Conditional Types 以及 Template Literal Types，避免过深的类继承层级。
* **异步并发与 Promise 安全**：
  * 异步函数必须显式声明返回类型（如 `Promise<UserDto>`），禁止隐式推导 `Promise<any>`。
  * 批量异步任务必须通过 `Promise.all` 或 `Promise.allSettled` 并发执行，严禁在 `for` 循环中无意义地串行 `await` 独立异步请求。
  * 所有的 `async` 操作必须具备完善的 Try/Catch 异常处理或全局 Error Boundary 回路。

---

## 2. LSP (vtsls / tsserver) 深度符号导航协议

在推导与重构复杂 TS 代码库时，你**必须**优先按照以下顺序调用 LSP 工具链：

1. **查找接口实现与多态引用**：调用 `mcp__vtsls__implementations` 查找 Interface 的具体实现类或对象字面量。
2. **符号定义与跨文件跳转**：调用 `mcp__vtsls__definition` 精准定位类型、组件或工具函数的源码位置。
3. **类型 Hover 深度检查**：遇到复杂的泛型推导链（如 Redux Toolkit、TRPC 或高阶函数），调用 `mcp__vtsls__hover` 仔细检查实际推导出的类型签名。

---

## 3. 确定性自修正算法 (Self-Correction Protocol)

当 `verify.sh` 拦截并报错时，严格按照以下日志类型定位并修正：

| 错误代码 / Linter 警告 | 常见根因 | 物理级标准修正方法 |
| :--- | :--- | :--- |
| **`TS2322`** (Type mismatch) | 赋予变量的实际类型与声明类型不符 | 检查数据源 Schema，补全缺失的属性字段或修正变量类型定义 |
| **`TS2339`** (Property does not exist on type) | 访问了联合类型中未共同拥有的属性 | 使用可辨识联合（Discriminated Union）或通过 `if ('prop' in obj)` 类型守卫收窄 |
| **`TS2531`** (Object is possibly 'null' / 'undefined') | 对可能为空的对象直接调用了属性或方法 | 补充 `?.` 可选链，或在访问前显式增加 `if (!obj) return;` 守卫 |
| **Biome / ESLint `@typescript-eslint/no-explicit-any`** | 代码中出现了禁止的 `any` 类型 | 用 `unknown` 替换 `any`，并配合 Zod 或类型守卫进行安全解析 |
| **Vitest / Jest Assertion Failed** | 单元测试断言不通过 | 检查输入参数与期望输出，修复底层业务逻辑或调整测试边界 |

---

## 4. 强制闭环验证 (Mandatory Verification)

每完成一次改动，**必须**运行以下命令，直到输出 `All TypeScript Verification Steps Passed!`：

`bash ~/.claude/skills/typescript-master/verify.sh "$PWD"`