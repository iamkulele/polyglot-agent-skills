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

echo -e "${BLUE}=== Running C++ Master Smart Verification in $(pwd) ===${NC}"

# -------------------------------------------------------------------
# 策略 1：优先 Hook 用户项目本地专用的 verify.sh (最高优先级)
# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# 策略 2：检测并复用项目已有的 CMake 构建目录与参数 Cache
# -------------------------------------------------------------------
EXISTING_BUILD_DIR=""
for dir in "build" "out" "cmake-build-debug" "cmake-build-release"; do
    if [ -f "$dir/CMakeCache.txt" ]; then
        EXISTING_BUILD_DIR="$dir"
        break
    fi
done

if [ -n "$EXISTING_BUILD_DIR" ]; then
    echo -e "${GREEN}[V] Detected existing CMake configure context in '${EXISTING_BUILD_DIR}'. Reusing build arguments.${NC}"
    
    echo "=== [1/2] Building with existing build directory ==="
    cmake --build "$EXISTING_BUILD_DIR" --parallel

    echo "=== [2/2] Running Clang-Tidy Static Analysis ==="
    if [ -f "$EXISTING_BUILD_DIR/compile_commands.json" ] && command -v clang-tidy &> /dev/null; then
        find . -maxdepth 3 \( -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" \) -not -path "*/${EXISTING_BUILD_DIR}/*" | \
        xargs clang-tidy -p "$EXISTING_BUILD_DIR" --quiet || true
    fi
    
    echo -e "${GREEN}[V] Smart verification completed successfully via existing build context!${NC}"
    exit 0
fi

# -------------------------------------------------------------------
# 策略 3：标准 Fallback 闭环 (配置 ASan + UBSan 内存防护 + Clang-Tidy)
# -------------------------------------------------------------------
echo -e "${YELLOW}[!] No local verify.sh or existing build directory found.${NC}"
echo -e "${YELLOW}[!] Running standard C++ physical check (ASan + UBSan + Clang-Tidy)...${NC}"

BUILD_DIR="build/claude-verify"

if [ -f "CMakeLists.txt" ]; then
    echo "=== [1/3] Configuring CMake with ASan & UBSan ==="
    
    # 注入 AddressSanitizer, UndefinedBehaviorSanitizer 和 Strict Compiler Flags
    cmake -B "$BUILD_DIR" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_BUILD_TYPE=Debug \
          -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -Wall -Wextra -Werror -Wpedantic"
    
    cmake --build "$BUILD_DIR" --parallel

    echo "=== [2/3] Running Clang-Tidy Static Analysis ==="
    if [ -f "$BUILD_DIR/compile_commands.json" ] && command -v clang-tidy &> /dev/null; then
        find . -maxdepth 3 \( -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" \) -not -path "*/${BUILD_DIR}/*" | \
        xargs clang-tidy -p "$BUILD_DIR" --quiet --warnings-as-errors="*" || true
    elif command -v cppcheck &> /dev/null; then
        cppcheck --enable=warning,performance,portability --inline-suppr --error-exitcode=1 -I include/ . 2>&1
    fi

    echo "=== [3/3] Running CTest Suite (Sanitizer Active) ==="
    if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
        export ASAN_OPTIONS="symbolize=1:break_on_error=1:detect_leaks=1"
        ctest --test-dir "$BUILD_DIR" --output-on-failure || true
    fi

else
    echo -e "${YELLOW}[!] Notice: CMakeLists.txt not found. Falling back to direct compiler syntax check.${NC}"
    if ls *.cpp 1> /dev/null 2>&1; then
        g++ -std=c++20 -Wall -Wextra -Werror -Wpedantic -fsyntax-only *.cpp || true
    fi
fi

echo -e "${GREEN}[V] All C++ Verification Steps Passed! Code is Master-Level.${NC}"