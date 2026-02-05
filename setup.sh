#!/bin/bash
# Cursor Slack Chat - Setup Script
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/CanonSystems/cursor-slack-chat/main/setup.sh | bash

set -e

INSTALL_DIR="$HOME/.cursor/mcp-servers/cursor-slack-chat"
MCP_CONFIG="$HOME/.cursor/mcp.json"
SETUP_FILE="$HOME/Desktop/cursor-setup.txt"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           🚀 Cursor Slack Chat Setup                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Ask if this is an admin setup or team member setup
echo "Are you the team admin setting up for the first time? (y/n)"
read -r IS_ADMIN

if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ADMIN SETUP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "First, create your Slack app:"
  echo "1. Go to https://api.slack.com/apps"
  echo "2. Click 'Create New App' → 'From an app manifest'"
  echo "3. Paste the manifest from:"
  echo "   https://raw.githubusercontent.com/CanonSystems/cursor-slack-chat/main/slack-app-manifest.yaml"
  echo "4. Install to your workspace"
  echo "5. Copy the Bot User OAuth Token (starts with xoxb-)"
  echo ""
  echo "Enter your Slack Bot Token (xoxb-...):"
  read -r BOT_TOKEN
  
  if [[ ! "$BOT_TOKEN" =~ ^xoxb- ]]; then
    echo "⚠️  Warning: Token should start with 'xoxb-'"
  fi
  
  # Generate the setup file for team members
  cat > "$SETUP_FILE" << EOF
🚀 Cursor Slack Chat - Team Setup Instructions

TOKEN: $BOT_TOKEN

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SETUP STEPS:

1. Open Terminal and run:
   curl -sL https://raw.githubusercontent.com/CanonSystems/cursor-slack-chat/main/setup.sh | bash

2. When asked "Are you the team admin?" answer: n

3. When asked for the token, paste:
   $BOT_TOKEN

4. The script will automatically configure Cursor for you

5. Restart Cursor

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions? Type /cursor-setup in Slack or ask your team admin.
EOF

  echo ""
  echo "✅ Created: $SETUP_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "NEXT STEP: Upload to Slack"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "1. In Slack, click 'More' → 'Files'"
  echo "2. Click '+ New' → upload cursor-setup.txt from your Desktop"
  echo "3. Team members can find it by searching 'cursor-setup' in Files"
  echo "   or by typing /cursor-setup"
  echo ""
  
  BOT_TOKEN_FOR_CONFIG="$BOT_TOKEN"
  
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "TEAM MEMBER SETUP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Get the token from Slack:"
  echo "  → Type /cursor-setup in any channel"
  echo "  → Or click 'More' → 'Files' → Search 'cursor-setup'"
  echo ""
  echo "Enter your Slack Bot Token (xoxb-...):"
  read -r BOT_TOKEN_FOR_CONFIG
fi

# Clone or update
echo ""
echo "📦 Installing Cursor Slack Chat..."
if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  git pull --quiet 2>/dev/null || true
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet https://github.com/CanonSystems/cursor-slack-chat.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Install dependencies
npm install --silent 2>/dev/null

echo "✅ MCP server installed"

# Update mcp.json
echo ""
echo "📝 Configuring Cursor..."

# Create the new server config
NEW_SERVER_CONFIG=$(cat << EOF
    "cursor-slack-chat": {
      "command": "node",
      "args": ["$INSTALL_DIR/index.js"],
      "env": {
        "SLACK_BOT_TOKEN": "$BOT_TOKEN_FOR_CONFIG"
      }
    }
EOF
)

if [ -f "$MCP_CONFIG" ]; then
  # File exists - check if cursor-slack-chat is already configured
  if grep -q "cursor-slack-chat" "$MCP_CONFIG"; then
    echo "⚠️  cursor-slack-chat already exists in mcp.json"
    echo "   Updating token..."
    
    # Use Python to update the JSON (more reliable than sed for JSON)
    python3 << PYTHON_SCRIPT
import json

with open("$MCP_CONFIG", "r") as f:
    config = json.load(f)

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"]["cursor-slack-chat"] = {
    "command": "node",
    "args": ["$INSTALL_DIR/index.js"],
    "env": {
        "SLACK_BOT_TOKEN": "$BOT_TOKEN_FOR_CONFIG"
    }
}

with open("$MCP_CONFIG", "w") as f:
    json.dump(config, f, indent=2)

print("✅ Updated mcp.json")
PYTHON_SCRIPT

  else
    # File exists but cursor-slack-chat not in it - add it
    python3 << PYTHON_SCRIPT
import json

with open("$MCP_CONFIG", "r") as f:
    config = json.load(f)

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"]["cursor-slack-chat"] = {
    "command": "node",
    "args": ["$INSTALL_DIR/index.js"],
    "env": {
        "SLACK_BOT_TOKEN": "$BOT_TOKEN_FOR_CONFIG"
    }
}

with open("$MCP_CONFIG", "w") as f:
    json.dump(config, f, indent=2)

print("✅ Added cursor-slack-chat to mcp.json")
PYTHON_SCRIPT

  fi
else
  # File doesn't exist - create it
  cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "cursor-slack-chat": {
      "command": "node",
      "args": ["$INSTALL_DIR/index.js"],
      "env": {
        "SLACK_BOT_TOKEN": "$BOT_TOKEN_FOR_CONFIG"
      }
    }
  }
}
EOF
  echo "✅ Created mcp.json"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SETUP COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄 Restart Cursor to activate the Slack integration"
echo ""
