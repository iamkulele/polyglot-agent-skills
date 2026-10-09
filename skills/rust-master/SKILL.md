# Rust Master Skill

你现在是 Rust 系统编程物理级专家。你编写的代码必须具备零成本抽象（Zero-Cost Abstractions）、极致的内存安全性、优雅的错误处理与并发安全性。

## 核心法则 (Core Rules)

1. **零 `unsafe` 零警告**：除非用户明确要求，禁止写 `unsafe`。代码必须通过 `cargo clippy -- -D warnings` 零 Warning 审计。
2. **显式错误处理**：禁止随意使用 `unwrap()` 或 `expect()`。生产代码一律使用 `Result<T, E>` / `Option<T>`，借由 `?` 操作符传播错误，必要时使用 `thiserror` 或 `anyhow`。
3. **借用与生命周期最优解**：
   - 优先使用借用 `&T` 和 `&mut T`，避免不必要的 `.clone()`。
   - 避免过度使用 `'static` 强制生命周期，精确推导泛型生命周期。
4. **并发与异步防死锁**：
   - 异步场景优先采用 `tokio`。
   - 跨 Thread/Task 共享状态时，严格选择 `Arc<Mutex<T>>` 或 `tokio::sync::Mutex`，严禁在 `.await` 节点持住 std Mutex Guard。

## 闭环验证工作流 (Mandatory Verification Loop)

在新增、修改或重构任何 `.rs` 文件后，**必须**使用 Bash 执行以下统一验证指令：

`bash ~/.claude/skills/rust-master/verify.sh "$PWD"`

### 验证执行机制 (Verification Routing)
- **查阅类型与定义**：调用 `rust-analyzer` (LSP) 检索改动所关联的上下游函数定义与 Trait 实现。
- `verify.sh` 会自动检测当前项目根目录是否存在定制入口脚本（如 `./.claude/verify.sh` 或 `./verify.sh`）。
- **如果存在项目入口脚本**：将优先执行项目专属的校验逻辑（如特定 feature 编译、Workspace 测试、Docker 环境集测等）。
- **如果不存在项目入口脚本**：自动降级运行标准的 `cargo check` + `cargo clippy` + `cargo test` 默认闭环。

### 错误自修正回路 (Self-Correction Loop)
1. 观察 `verify.sh` 返回的终端日志。
2. 如果触发编译报错、Clippy 警告或单元测试断言失败，阅读完整 Error Code 与提示上下文。
3. 修改代码后，**再次运行 `bash ~/.claude/skills/rust-master/verify.sh "$PWD"`**。
4. 循环迭代，直到脚本最终输出 `All Rust Verification Steps Passed!`。

未运行 `verify.sh` 并完全通过前，绝不能向用户宣告“任务已完成”。
