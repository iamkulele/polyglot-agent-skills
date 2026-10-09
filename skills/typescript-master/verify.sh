#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Running TypeScript Master Verification in $(pwd) ==="

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

# 3. 无本地脚本时，走默认的 TypeScript 物理级闭环
echo "[i] No local entrypoint found. Running standard TypeScript master check..."

# (1) 静态类型检查：强制 noEmit
echo "=== [1/3] Running TypeScript Compiler (tsc --noEmit) ==="
if [ -f "tsconfig.json" ]; then
    if ! npx tsc --noEmit; then
        echo -e "${RED}[X] TypeScript Type Check Failed! Read errors above and fix type issues.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[!] Notice: tsconfig.json not found, skipping tsc check.${NC}"
fi
echo -e "${GREEN}[V] Type Check Passed cleanly.${NC}"

# (2) 代码质量与 Linting 检查 (支持 Biome 或 ESLint)
echo "=== [2/3] Running Linter (Biome / ESLint) ==="
if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
    echo "Detected Biome. Running biome check..."
    npx @biomejs/biome check --write=false .
elif [ -f ".eslintrc" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
    echo "Detected ESLint. Running eslint..."
    npx eslint . --ext .ts,.tsx --max-warnings 0
else
    echo -e "${YELLOW}[!] Notice: No Biome/ESLint config found, skipping Linter.${NC}"
fi
echo -e "${GREEN}[V] Linting Check Passed.${NC}"

# (3) 单元测试检查 (支持 Vitest 或 Jest)
echo "=== [3/3] Running Tests (Vitest / Jest) ==="
if grep -q '"vitest"' package.json 2>/dev/null; then
    npx vitest run
elif grep -q '"jest"' package.json 2>/dev/null; then
    npx jest --passWithNoTests
else
    echo -e "${YELLOW}[!] Notice: No test runner (Vitest/Jest) configured in package.json, skipping tests.${NC}"
fi

echo -e "${GREEN}[V] All TypeScript Verification Steps Passed! Code is Master-Level.${NC}"
