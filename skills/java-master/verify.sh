#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Running Java Master Verification in $(pwd) ==="

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

# 3. 无本地脚本时，走默认的 Java 物理级闭环 (自动识别 Maven 或 Gradle)
echo "[i] No local entrypoint found. Running standard Java master check..."

if [ -f "pom.xml" ]; then
    echo "=== [Maven Project Detected] ==="
    MVN_CMD="./mvnw"
    if [ ! -f "$MVN_CMD" ]; then
        MVN_CMD="mvn"
    fi

    echo "Running compile & test-compile..."
    $MVN_CMD test-compile --batch-mode

    echo "Running unit tests & verify..."
    $MVN_CMD test --batch-mode

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "=== [Gradle Project Detected] ==="
    GRADLE_CMD="./gradlew"
    if [ ! -f "$GRADLE_CMD" ]; then
        GRADLE_CMD="gradle"
    fi

    echo "Running gradle check & test..."
    $GRADLE_CMD check

else
    echo -e "${RED}[X] Neither pom.xml nor build.gradle found in $(pwd)${NC}"
    exit 1
fi

echo -e "${GREEN}[V] All Java Verification Steps Passed! Code is Master-Level.${NC}"
