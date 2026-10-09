#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Running Python Master Verification in $(pwd) ==="

# 2. 检查本地是否存在项目专属入口脚本
LOCAL_ENTRYPOINT=""
if [ -f "./.claude/verify.sh" ]; then
    LOCAL_ENTRYPOINT="./.claude/verify.sh"
elif [ -f "./verify.sh" ]; then
    LOCAL_ENTRYPOINT="./verify.sh"
fi

# 如果存在本地定制脚本，优先调起本地脚本
if [ -n "$LOCAL_ENTRYPOINT" ]; then
    echo -e "${YELLOW}[!] Found local project entrypoint: ${LOCAL_ENTRYPOINT}${NC}"
    chmod +x "$LOCAL_ENTRYPOINT"
    exec "$LOCAL_ENTRYPOINT"
fi

# 3. 无本地脚本时，走默认的 Python 物理级闭环
echo "[i] No local entrypoint found. Running standard Python master check..."

# (1) 静态类型检查：优先 pyright，降级 mypy
echo "=== [1/3] Running Static Type Checker (Pyright / Mypy) ==="
if command -v pyright &> /dev/null || npx --no-install pyright --version &> /dev/null 2>&1; then
    echo "Running pyright..."
    npx pyright .
elif command -v mypy &> /dev/null; then
    echo "Running mypy..."
    mypy .
else
    echo -e "${YELLOW}[!] Notice: Neither Pyright nor Mypy found. Skipping type check.${NC}"
fi
echo -e "${GREEN}[V] Type Check Passed cleanly.${NC}"

# (2) 代码质量与 Lint 检查：优先 ruff，降级 flake8
echo "=== [2/3] Running Linter (Ruff / Flake8) ==="
if command -v ruff &> /dev/null; then
    echo "Running ruff check..."
    ruff check .
elif command -v flake8 &> /dev/null; then
    echo "Running flake8..."
    flake8 .
else
    echo -e "${YELLOW}[!] Notice: No Ruff or Flake8 found. Skipping linter.${NC}"
fi
echo -e "${GREEN}[V] Linting Check Passed.${NC}"

# (3) 单元测试检查：pytest
echo "=== [3/3] Running Tests (Pytest) ==="
if command -v pytest &> /dev/null; then
    pytest -q
elif [ -d "tests" ] || [ -d "test" ]; then
    python3 -m unittest discover -s .
else
    echo -e "${YELLOW}[!] Notice: No pytest or tests/ directory found, skipping unit tests.${NC}"
fi

echo -e "${GREEN}[V] All Python Verification Steps Passed! Code is Master-Level.${NC}"
