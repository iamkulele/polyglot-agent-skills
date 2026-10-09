#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 获取 install.sh 所在的绝对路径，确保不受当前终端 PWD 影响
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}=== Polyglot Agent Skills Installer ===${NC}\n"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
CLAUDE_CONFIG="$HOME/.claude.json"
SETTINGS_CONFIG="$CLAUDE_DIR/settings.json"

mkdir -p "$SKILLS_DIR"
mkdir -p "$CLAUDE_DIR"

# ----------------------------------------------------
# 1. 部署 Skills 资源
# ----------------------------------------------------
echo -e "${YELLOW}[1/3] Deploying skills to $SKILLS_DIR...${NC}"
if [ -d "skills" ]; then
    cp -r skills/* "$SKILLS_DIR/"
    find "$SKILLS_DIR" -type f -name "verify.sh" -exec chmod +x {} \;
    echo -e "${GREEN}[V] Skills files deployed & made executable.${NC}"
else
    echo -e "${RED}[X] 'skills/' directory not found in current path!${NC}"
    exit 1
fi

# ----------------------------------------------------
# 2. 备份并合并 MCP 配置 (~/.claude.json)
# ----------------------------------------------------
echo -e "${YELLOW}[2/3] Configuring MCP Servers in $CLAUDE_CONFIG...${NC}"

if [ -f "$CLAUDE_CONFIG" ]; then
    BACKUP_FILE="${CLAUDE_CONFIG}.bak_${TIMESTAMP}"
    cp "$CLAUDE_CONFIG" "$BACKUP_FILE"
    echo -e "${BLUE}  -> Created backup: $BACKUP_FILE${NC}"
else
    echo -e "${BLUE}  -> $CLAUDE_CONFIG does not exist yet. Will create a new one.${NC}"
fi

# 传入 SCRIPT_DIR 给 Python 处理绝对路径
python3 - "$SCRIPT_DIR" "$CLAUDE_CONFIG" << 'EOF'
import json
import os
import sys
import glob

script_dir = sys.argv[1]
config_path = sys.argv[2]

config = {}
if os.path.exists(config_path):
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except Exception as e:
        print(f"  [!] Notice: Failed to parse existing {config_path}: {e}")
        config = {}

if "mcpServers" not in config:
    config["mcpServers"] = {}

# 1. 绝对路径扫描 skills/*/mcp.json
search_pattern = os.path.join(script_dir, "skills", "*", "mcp.json")
skill_mcp_files = glob.glob(search_pattern)

if not skill_mcp_files:
    print(f"  [!] Warning: No mcp.json files found matching pattern: {search_pattern}")

for mcp_file in skill_mcp_files:
    try:
        with open(mcp_file, "r", encoding="utf-8") as f:
            skill_mcp = json.load(f)
            if "mcpServers" in skill_mcp:
                for server_name, server_conf in skill_mcp["mcpServers"].items():
                    config["mcpServers"][server_name] = server_conf
                    print(f"  -> Registered MCP Server: '{server_name}' (from {os.path.basename(os.path.dirname(mcp_file))})")
    except Exception as e:
        print(f"  [X] Failed to parse {mcp_file}: {e}")

# 2. 写回配置文件
with open(config_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

EOF

echo -e "${GREEN}[V] MCP Servers merged into $CLAUDE_CONFIG.${NC}"

# ----------------------------------------------------
# 3. 备份并更新免打扰权限 (~/.claude/settings.json)
# ----------------------------------------------------
echo -e "${YELLOW}[3/3] Setting up permission whitelist in $SETTINGS_CONFIG...${NC}"

if [ -f "$SETTINGS_CONFIG" ]; then
    BACKUP_SETTINGS="${SETTINGS_CONFIG}.bak_${TIMESTAMP}"
    cp "$SETTINGS_CONFIG" "$BACKUP_SETTINGS"
    echo -e "${BLUE}  -> Created backup: $BACKUP_SETTINGS${NC}"
fi

python3 - << 'EOF'
import json
import os

settings_path = os.path.expanduser("~/.claude/settings.json")
os.makedirs(os.path.dirname(settings_path), exist_ok=True)

settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, "r") as f:
            settings = json.load(f)
    except Exception:
        settings = {}

if "permissions" not in settings:
    settings["permissions"] = {}

if "allow" not in settings["permissions"]:
    settings["permissions"]["allow"] = []

rule = "Bash(bash ~/.claude/skills/*)"
if rule not in settings["permissions"]["allow"]:
    settings["permissions"]["allow"].append(rule)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

EOF

echo -e "${GREEN}[V] Permission whitelist rule added to $SETTINGS_CONFIG.${NC}"

echo -e "\n${GREEN}===================================================${NC}"
echo -e "${GREEN} Successfully installed Polyglot Agent Skills! ${NC}"
echo -e "${GREEN}===================================================${NC}"
