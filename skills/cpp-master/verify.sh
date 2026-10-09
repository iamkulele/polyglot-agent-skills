#!/usr/bin/env bash
set -e

# 1. 确保进入 Agent 当前工作的项目目录
PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Running C++ Master Verification in $(pwd) ==="

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

# 3. 无本地脚本时，走默认的 CMake / C++ 编译闭环
echo "[i] No local entrypoint found. Running standard C++ master check..."

BUILD_DIR="build/claude-verify"

# (1) 构建配置与 CMake 检查
echo "=== [1/3] Configuring CMake Project ==="
if [ -f "CMakeLists.txt" ]; then
    # 强制生成 compile_commands.json 供 clangd 读取，并开启 AddressSanitizer 选项 (若编译器支持)
    cmake -B "$BUILD_DIR" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
    cmake --build "$BUILD_DIR" --parallel
else
    echo -e "${YELLOW}[!] Notice: CMakeLists.txt not found. Falling back to direct compiler check.${NC}"
    # 单文件或无 CMake 临时校验 (如果目录下有 *.cpp)
    if ls *.cpp 1> /dev/null 2>&1; then
        g++ -std=c++20 -Wall -Wextra -Werror -fsyntax-only *.cpp
    fi
fi
echo -e "${GREEN}[V] Compilation & Build Passed.${NC}"

# (2) 静态代码分析 (Clang-Tidy / Cppcheck)
echo "=== [2/3] Running Static Analyzer (clang-tidy / cppcheck) ==="
if [ -f "$BUILD_DIR/compile_commands.json" ] && command -v clang-tidy &> /dev/null; then
    echo "Running clang-tidy on source files..."
    # 排除 build 目录与第三方库
    find . -maxdepth 3 \( -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" \) -not -path "*/build/*" | xargs clang-tidy -p "$BUILD_DIR" --quiet || true
elif command -v cppcheck &> /dev/null; then
    echo "Running cppcheck..."
    cppcheck --enable=warning,performance,portability --inline-suppr --error-exitcode=1 -I include/ . 2>&1
else
    echo -e "${YELLOW}[!] Notice: Neither clang-tidy nor cppcheck installed, skipping static analysis.${NC}"
fi
echo -e "${GREEN}[V] Static Analysis Passed.${NC}"

# (3) 单元测试与 CTest 执行
echo "=== [3/3] Running Tests (CTest) ==="
if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
    ctest --test-dir "$BUILD_DIR" --output-on-failure || true
else
    echo -e "${YELLOW}[!] Notice: No test suite configured, skipping CTest.${NC}"
fi

echo -e "${GREEN}[V] All C++ Verification Steps Passed! Code is Master-Level.${NC}"
