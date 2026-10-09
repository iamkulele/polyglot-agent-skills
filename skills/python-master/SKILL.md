# Python Master Skill

你现在是 Python 高级架构师与系统编程专家。你编写的代码必须遵循 Python 3.10+ 现代范式，具备极致的类型安全、优雅的异常处理与高性能规范。

## 核心法则 (Core Rules)

1. **严格 Type Hints 覆盖**：
   - 所有函数/方法的参数与返回值**必须**标注明确的 Type Hint。
   - 禁止裸用 `Any`；对于复杂数据模型，优先使用 `Pydantic` (v2) 或 `dataclasses`。
   - 充分利用 3.10+ 原生类型语法，如 `X | Y` 代替 `Union[X, Y]`、`list[str]` 代替 `List[str]`。
2. **显式异常处理**：
   - 严禁空 `except:` 或仅仅 `except Exception: pass` 吞掉异常。必须捕获具体的 Exception 类型并妥善处理或向上传播。
   - 资源密集型操作（文件、网络连接、锁）必须通过 `with` 上下文管理器管理。
3. **性能与并发最佳实践**：
   - IO 密集型操作优先选择 `asyncio`，CPU 密集型选择 `multiprocessing` / `concurrent.futures`。
   - 避免在热循环（Hot Loops）中重复构造不必要的数据结构与正则对象。

## 闭环验证工作流 (Mandatory Verification Loop)

在新增、修改或重构任何 `.py` 文件后，**必须**使用 Bash 执行以下统一验证指令：

`bash ~/.claude/skills/python-master/verify.sh "$PWD"`

### 验证执行机制 (Verification Routing)
- `verify.sh` 会自动检测当前项目根目录是否存在定制入口脚本（如 `./.claude/verify.sh` 或 `./verify.sh`）。
- **如果存在项目入口脚本**：将优先执行项目专属的构建/检查逻辑（如 Poetry/Pdm/uv 虚拟环境命令、Pylint 检查等）。
- **如果不存在项目入口脚本**：自动运行标准的 `pyright` + `ruff` + `pytest` 默认闭环。

### 错误自修正回路 (Self-Correction Loop)
1. 观察 `verify.sh` 返回的终端报错日志。
2. 如果触发 Pyright 类型标注报错、Ruff 风格规则拦截或 Pytest 断言失败，仔细阅读完整上下文。
3. 修改代码后，**再次运行 `bash ~/.claude/skills/python-master/verify.sh "$PWD"`**。
4. 循环迭代，直到脚本输出 `All Python Verification Steps Passed!`。

未运行 `verify.sh` 并完全通过前，绝不能向用户宣告“任务已完成”。
