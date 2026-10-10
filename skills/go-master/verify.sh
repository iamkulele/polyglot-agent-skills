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

echo -e "${BLUE}=== Running Go Master Smart Verification in $(pwd) ===${NC}"

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

# 3. 检查是否存在 go.mod
if [ ! -f "go.mod" ]; then
    echo -e "${RED}[X] Error: go.mod not found in current directory $(pwd).${NC}"
    exit 1
fi

echo -e "${GREEN}[V] Detected go.mod. Running standard Go master verification loop...${NC}"

# (1) 基础编译与静态检查 (go vet)
echo "=== [1/3] Running Go Vet & Compile Check ==="
go vet ./...
echo -e "${GREEN}[V] Go Vet Check Passed.${NC}"

# (2) 代码质量与静态分析 (golangci-lint)
echo "=== [2/3] Running Linter (golangci-lint) ==="
if command -v golangci-lint &> /dev/null; then
    golangci-lint run ./...
else
    echo -e "${YELLOW}[!] Notice: golangci-lint not installed, skipping deep static analysis.${NC}"
fi
echo -e "${GREEN}[V] Linting Phase Completed.${NC}"

# (3) 单元测试与竞态检测 (-race)
echo "=== [3/3] Running Tests with Race Detector ==="
go test -race -v ./...

echo -e "${GREEN}[V] All Go Verification Steps Passed! Code is Master-Level.${NC}"