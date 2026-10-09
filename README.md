# Polyglot Agent Skills for Claude Code

Production-grade, tool-augmented, self-correcting **True Mastery Skills** for Claude Code across six core programming languages: **Rust**, **TypeScript**, **Python**, **C++**, **Go**, and **Java**.

This repository bridges the gap between simple prompt engineering and genuine software mastery by enforcing domain-specific directives, native Language Server Protocol (LSP) symbol navigation via MCP, and automated, compiler-in-the-loop self-correction.

---

## 💡 Core Philosophy

True Agent Mastery relies on a tri-fold architecture:

1. **Rules & Directives (`SKILL.md`)**: Language-specific best practices, architectural idioms, safety rules, and self-correction instructions that guide Claude's thinking process.
2. **LSP Integration (`mcp.json`)**: Deep semantic comprehension via Model Context Protocol (MCP) language servers (`rust-analyzer`, `vtsls`, `pyright`, `clangd`, `gopls`, `jdtls`) rather than shallow text grep.
3. **Compiler-in-the-Loop (`verify.sh`)**: Automated execution loops running compilers, linter suites, and test runners to give Claude immediate feedback and trigger self-correction cycles.

---

## 🏗️ Monorepo Architecture

The repository employs a **Template Method** design pattern. A global orchestrator dynamically delegates to a project-specific entrypoint script if one exists (`./.claude/verify.sh` or `./verify.sh`), falling back to standard language toolchains when custom configurations are absent.

```text
polyglot-agent-skills/
├── install.sh                     # Dynamic installer & MCP merger with auto-backup
├── README.md                      # Repository documentation
└── skills/
    ├── rust-master/               # Rust Mastery (cargo, clippy, rust-analyzer)
    │   ├── SKILL.md
    │   ├── mcp.json
    │   └── verify.sh
    ├── typescript-master/         # TypeScript Mastery (tsc, biome/eslint, vtsls)
    │   ├── SKILL.md
    │   ├── mcp.json
    │   └── verify.sh
    ├── python-master/             # Python Mastery (pyright, ruff, pytest)
    │   ├── SKILL.md
    │   ├── mcp.json
    │   └── verify.sh
    ├── cpp-master/                # C++ Mastery (cmake, clang-tidy, clangd)
    │   ├── SKILL.md
    │   ├── mcp.json
    │   └── verify.sh
    ├── go-master/                 # Go Mastery (go vet, golangci-lint, gopls)
    │   ├── SKILL.md
    │   ├── mcp.json
    │   └── verify.sh
    └── java-master/               # Java Mastery (mvn/gradle, checkstyle, jdtls)
        ├── SKILL.md
        ├── mcp.json
        └── verify.sh
```

---

## 🚀 Installation & Usage

### 1. Installation

Run the universal installation script from the root of this repository:

```bash
chmod +x install.sh
./install.sh
```

#### What `install.sh` does automatically:
- **Deploys Skills**: Copies all skills to `~/.claude/skills/` and sets execution permissions.
- **Configures MCP**: Merges all language-specific `mcp.json` configs into `~/.claude.json`.
- **Configures Whitelist**: Updates `~/.claude/settings.json` to allow `Bash(bash ~/.claude/skills/*)` for uninterrupted execution.
- **Timestamped Backups**: Automatically creates `.bak_<timestamp>` backups of any modified configuration files prior to mutation.

### 2. Usage

Restart your `claude` CLI session to load the updated configuration and MCP servers.

When asking Claude to write or refactor code in a target project, Claude will automatically invoke the corresponding skill verification loop:

```bash
# Example invocation executed internally by Claude Code:
bash ~/.claude/skills/rust-master/verify.sh "$PWD"
```

---

## 🛠️ Local Entrypoint Customization

If your target project requires custom build steps, specific feature flags, Docker environments, or monorepo sub-package testing, simply create a local verification script in your project root:

```bash
# Option A (Recommended)
mkdir -p .claude
touch .claude/verify.sh
chmod +x .claude/verify.sh

# Option B
touch verify.sh
chmod +x verify.sh
```

### Example Local Entrypoint (`.claude/verify.sh`)
```bash
#!/usr/bin/env bash
set -e

echo "-> Executing custom workspace checks..."
cargo check --all-targets --message-format=short
cargo clippy --all-targets -- -D warnings
cargo test --all --quiet
```

When present, the global `verify.sh` will delegate execution directly to your project's local script.

---

## 🌐 Language Matrix

| Language | MCP Language Server | Default Verification Suite | Core Rules & Paradigms |
| :--- | :--- | :--- | :--- |
| **Rust** | `rust-analyzer` | `cargo check` + `clippy` + `cargo test` | Zero-cost abstractions, memory safety, 0 warnings, explicit error handling (`Result`/`Option`). |
| **TypeScript**| `vtsls` | `tsc --noEmit` + `biome`/`eslint` + `vitest`/`jest` | Strict type narrowing, no `any`, proper `async/await` error boundaries, discriminated unions. |
| **Python** | `pyright` | `pyright`/`mypy` + `ruff` + `pytest` | Python 3.10+ typing, explicit exception handling, Context Managers (`with`), no silent `except`. |
| **C++** | `clangd` | `cmake` + `clang-tidy`/`cppcheck` + `ctest` | C++20/23 standard, RAII memory management, no raw owning pointers, zero undefined behavior (UB). |
| **Go** | `gopls` | `go vet` + `golangci-lint` + `go test -race` | Go 1.22+ idioms, explicit error wrapping (`%w`), `context.Context` propagation, Goroutine leak prevention. |
| **Java** | `jdtls` | `mvn test-compile` / `./gradlew check` | Java 17/21+ LTS, Records, Pattern Matching, NPE prevention via `Optional`, `try-with-resources`. |

---

## 🔒 Security & Permissions

To ensure smooth agent operations without constant permission popups, `install.sh` registers execution rules in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash ~/.claude/skills/*)"
    ]
  }
}
```

This guarantees that Claude can run validation loops and self-correct seamlessly in non-interactive mode.