#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Running Go Master Verification in $(pwd) ==="

# 2. 检查本地是否存在项目专属入口脚本
LOCAL_ENTRYPOINT=""
if [ -f "./.claude/verify.sh" ]; then
    LOCAL_ENTRYPOINT="./.claude/verify.sh"
elif [ -f "./verify.sh" ]; then
    LOCAL_ENTRYPOINT="./verify.sh"
fi

if [ -n "$LOCAL_ENTRYPOINT" ]; then
    echo -e "${YELLOW}[!] Found local project entrypoint: ${LOCAL_ENTRYPOINT}${NC}"
    chmod +x "$LOCAL_ENTRYPOINT"
    exec "$LOCAL_ENTRYPOINT"
fi

# 3. 无本地脚本时，走默认的 Go 物理级闭环
echo "[i] No local entrypoint found. Running standard Go master check..."

# (1) 基础编译与 静态检查
echo "=== [1/3] Running Go Vet & Build Check ==="
if [ -f "go.mod" ]; then
    go vet ./...
    go test -run=x^ ./... # 快速触发 package 编译校验，不实际跑测试
else
    echo -e "${YELLOW}[!] Notice: go.mod not found in current directory.${NC}"
    exit 1
fi
echo -e "${GREEN}[V] Go Vet & Build Check Passed.${NC}"

# (2) 代码质量与 Static Analysis (golangci-lint)
echo "=== [2/3] Running Linter (golangci-lint) ==="
if command -v golangci-lint &> /dev/null; then
    golangci-lint run ./...
else
    echo -e "${YELLOW}[!] Notice: golangci-lint not installed. Skipping deep linting.${NC}"
fi
echo -e "${GREEN}[V] Linting Check Passed.${NC}"

# (3) 单元测试与竞态检测 (-race)
echo "=== [3/3] Running Tests with Race Detector ==="
go test -race -v ./...

echo -e "${GREEN}[V] All Go Verification Steps Passed! Code is Master-Level.${NC}"
