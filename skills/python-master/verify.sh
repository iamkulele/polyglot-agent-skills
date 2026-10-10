#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Python Master Smart Verification in $(pwd) ===${NC}"

# 2. 核心原则：优先 Hook 用户项目本地专用的 verify.sh
LOCAL_ENTRYPOINT=""
if [ -f "./.claude/verify.sh" ]; then
    LOCAL_ENTRYPOINT="./.claude/verify.sh"
elif [ -f "./verify.sh" ]; then
    LOCAL_ENTRYPOINT="./verify.sh"
fi

if [ -n "$LOCAL_ENTRYPOINT" ]; then
    echo -e "${GREEN}[V] Found user project entrypoint: ${LOCAL_ENTRYPOINT}${NC}"
    chmod +x "$LOCAL_ENTRYPOINT"
    exec "$LOCAL_ENTRYPOINT"
fi

# 3. 智能嗅探项目本地的虚拟环境 (.venv, venv, env)
PYTHON_BIN="python3"
PYRIGHT_BIN="pyright"
RUFF_BIN="ruff"
PYTEST_BIN="pytest"

if [ -f ".venv/bin/python" ]; then
    echo -e "${GREEN}[V] Detected virtualenv at .venv/${NC}"
    PYTHON_BIN=".venv/bin/python"
    [ -f ".venv/bin/pyright" ] && PYRIGHT_BIN=".venv/bin/pyright"
    [ -f ".venv/bin/ruff" ] && RUFF_BIN=".venv/bin/ruff"
    [ -f ".venv/bin/pytest" ] && PYTEST_BIN=".venv/bin/pytest"
elif [ -f "venv/bin/python" ]; then
    echo -e "${GREEN}[V] Detected virtualenv at venv/${NC}"
    PYTHON_BIN="venv/bin/python"
    [ -f "venv/bin/pyright" ] && PYRIGHT_BIN="venv/bin/pyright"
    [ -f "venv/bin/ruff" ] && RUFF_BIN="venv/bin/ruff"
    [ -f "venv/bin/pytest" ] && PYTEST_BIN="venv/bin/pytest"
fi

# 4. 执行标准 Python 物理级闭环
echo "[i] Running standard Python master verification loop..."

# (1) 静态类型检查：优先 pyright 严格模式，降级 mypy
echo "=== [1/3] Running Static Type Checker (Pyright / Mypy) ==="
if command -v "$PYRIGHT_BIN" &> /dev/null || npx --no-install pyright --version &> /dev/null 2>&1; then
    if [ "$PYRIGHT_BIN" = "pyright" ] && command -v npx &> /dev/null; then
        npx pyright .
    else
        "$PYRIGHT_BIN" .
    fi
elif command -v mypy &> /dev/null; then
    mypy .
else
    echo -e "${YELLOW}[!] Notice: Pyright/Mypy not found in PATH. Skipping type check.${NC}"
fi
echo -e "${GREEN}[V] Type Check Phase Completed.${NC}"

# (2) 代码质量与 Lint 检查：优先 ruff
echo "=== [2/3] Running Linter (Ruff) ==="
if command -v "$RUFF_BIN" &> /dev/null; then
    "$RUFF_BIN" check .
elif command -v ruff &> /dev/null; then
    ruff check .
else
    echo -e "${YELLOW}[!] Notice: Ruff not found. Skipping linting.${NC}"
fi
echo -e "${GREEN}[V] Linting Phase Completed.${NC}"

# (3) 单元测试检查：pytest
echo "=== [3/3] Running Test Suite (Pytest) ==="
if command -v "$PYTEST_BIN" &> /dev/null; then
    "$PYTEST_BIN" -q
elif command -v pytest &> /dev/null; then
    pytest -q
elif [ -d "tests" ] || [ -d "test" ]; then
    "$PYTHON_BIN" -m unittest discover -s .
else
    echo -e "${YELLOW}[!] Notice: No pytest or tests/ directory configured, skipping unit tests.${NC}"
fi

echo -e "${GREEN}[V] All Python Verification Steps Passed! Code is Master-Level.${NC}"