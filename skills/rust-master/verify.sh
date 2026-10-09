#!/usr/bin/env bash
set -e

# 强制切换到 Agent 传入的目标项目目录
TARGET_DIR="${1:-$PWD}"
cd "$TARGET_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Running Rust Master Verification in $(pwd) ==="

# 检查本地是否有自定义的入口脚本 (支持两种常规命名)
LOCAL_ENTRYPOINT=""
if [ -f "./.claude/verify.sh" ]; then
    LOCAL_ENTRYPOINT="./.claude/verify.sh"
elif [ -f "./verify.sh" ]; then
    LOCAL_ENTRYPOINT="./verify.sh"
fi

# 如果本地存在入口脚本，优先调用本地的入口脚本
if [ -n "$LOCAL_ENTRYPOINT" ]; then
    echo -e "${YELLOW}[!] Found local project entrypoint: ${LOCAL_ENTRYPOINT}${NC}"
    chmod +x "$LOCAL_ENTRYPOINT"
    exec "$LOCAL_ENTRYPOINT"
fi

# 如果本地没有定制脚本，走默认的通用闭环逻辑 (Default Fallback)
echo "[i] No local entrypoint found. Running standard Rust master check..."

# 设置独立的 CARGO_TARGET_DIR，彻底隔离 IDE/LSP 的文件锁冲突
export CARGO_TARGET_DIR="target/claude-verify"

# 检查当前目录是否存在 Cargo.toml
if [ ! -f "Cargo.toml" ]; then
    echo "[X] Error: No Cargo.toml found in $(pwd)"
    exit 1
fi

echo "=== [1/3] Running Cargo Check ==="
# 使用 timeout 30s 规避无限挂起
if ! timeout 30s cargo check --message-format=short 2>&1; then
    echo -e "${RED}[X] Cargo Check Failed or Timed out!${NC}"
    exit 1
fi
echo -e "${GREEN}[V] Cargo Check Passed.${NC}"

echo "=== [2/3] Running Cargo Clippy (Lint & Best Practices) ==="
if ! timeout 30s cargo clippy -- -D warnings 2>&1; then
    echo -e "${RED}[X] Clippy Lint Failed or Timed out!${NC}"
    exit 2
fi
echo -e "${GREEN}[V] Cargo Clippy Passed cleanly.${NC}"

echo "=== [3/3] Running Cargo Test ==="
if ! timeout 60s cargo test --quiet 2>&1; then
    echo -e "${RED}[X] Cargo Test Failed or Timed out!${NC}"
    exit 3
fi

echo -e "${GREEN}[V] All Rust Verification Steps Passed! Code is Master-Level.${NC}"
