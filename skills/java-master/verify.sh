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

echo -e "${BLUE}=== Running Java Master Smart Verification in $(pwd) ===${NC}"

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

# 3. 自动识别构建工具 (Maven vs Gradle)
if [ -f "pom.xml" ]; then
    echo -e "${GREEN}[V] Detected Maven project (pom.xml)${NC}"
    MVN_CMD="./mvnw"
    if [ ! -f "$MVN_CMD" ]; then
        MVN_CMD="mvn"
    fi

    echo "=== [1/2] Compiling sources and tests ==="
    $MVN_CMD test-compile --batch-mode

    echo "=== [2/2] Running test suite ==="
    $MVN_CMD test --batch-mode

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo -e "${GREEN}[V] Detected Gradle project (build.gradle)${NC}"
    GRADLE_CMD="./gradlew"
    if [ ! -f "$GRADLE_CMD" ]; then
        GRADLE_CMD="gradle"
    fi

    echo "=== [1/1] Running Gradle check & test suite ==="
    $GRADLE_CMD check

else
    echo -e "${RED}[X] Error: Neither pom.xml nor build.gradle found in $(pwd).${NC}"
    exit 1
fi

echo -e "${GREEN}[V] All Java Verification Steps Passed! Code is Master-Level.${NC}"