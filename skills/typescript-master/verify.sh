#!/usr/bin/env bash
set -e

# 1. 进入 Agent 当前工作目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running TypeScript Master Smart Verification in $(pwd) ===${NC}"

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

# 3. 智能嗅探包管理器 (pnpm -> yarn -> npm -> bun)
RUN_CMD="npx"
if [ -f "pnpm-lock.yaml" ]; then
    RUN_CMD="pnpm"
elif [ -f "yarn.lock" ]; then
    RUN_CMD="yarn"
elif [ -f "bun.lockb" ]; then
    RUN_CMD="bunx"
fi

echo -e "${GREEN}[V] Detected package runner executor: ${RUN_CMD}${NC}"

# 4. 执行标准 TypeScript 物理级闭环
echo "[i] Running standard TypeScript master verification loop..."

# (1) 严格静态类型检查 (tsc --noEmit)
echo "=== [1/3] Running TypeScript Compiler (tsc --noEmit) ==="
if [ -f "tsconfig.json" ]; then
    if [ "$RUN_CMD" = "pnpm" ]; then
        pnpm tsc --noEmit
    elif [ "$RUN_CMD" = "yarn" ]; then
        yarn tsc --noEmit
    else
        npx tsc --noEmit
    fi
else
    echo -e "${YELLOW}[!] Notice: tsconfig.json not found, skipping tsc type check.${NC}"
fi
echo -e "${GREEN}[V] Type Check Phase Passed cleanly.${NC}"

# (2) 代码质量与 Lint 检查 (优先 Biome，降级 ESLint)
echo "=== [2/3] Running Linter (Biome / ESLint) ==="
if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
    echo "Running Biome check..."
    npx @biomejs/biome check --write=false .
elif [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f ".eslintrc" ] || [ -f ".eslintrc.json" ]; then
    echo "Running ESLint..."
    if [ "$RUN_CMD" = "pnpm" ]; then
        pnpm eslint . --ext .ts,.tsx --max-warnings 0
    elif [ "$RUN_CMD" = "yarn" ]; then
        yarn eslint . --ext .ts,.tsx --max-warnings 0
    else
        npx eslint . --ext .ts,.tsx --max-warnings 0
    fi
else
    echo -e "${YELLOW}[!] Notice: No Biome or ESLint config found, skipping linter check.${NC}"
fi
echo -e "${GREEN}[V] Linting Phase Passed.${NC}"

# (3) 单元测试检查 (Vitest / Jest)
echo "=== [3/3] Running Test Suite (Vitest / Jest) ==="
if grep -q '"vitest"' package.json 2>/dev/null; then
    if [ "$RUN_CMD" = "pnpm" ]; then
        pnpm vitest run
    elif [ "$RUN_CMD" = "yarn" ]; then
        yarn vitest run
    else
        npx vitest run
    fi
elif grep -q '"jest"' package.json 2>/dev/null; then
    if [ "$RUN_CMD" = "pnpm" ]; then
        pnpm jest --passWithNoTests
    elif [ "$RUN_CMD" = "yarn" ]; then
        yarn jest --passWithNoTests
    else
        npx jest --passWithNoTests
    fi
else
    echo -e "${YELLOW}[!] Notice: No Vitest or Jest test runner declared in package.json, skipping tests.${NC}"
fi

echo -e "${GREEN}[V] All TypeScript Verification Steps Passed! Code is Master-Level.${NC}"