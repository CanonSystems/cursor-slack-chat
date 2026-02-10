# Cursor Slack Chat

Chat with your team on Slack directly from Cursor. Message team members and channels as things come up during development.

## Features

| Tool | Description |
|------|-------------|
| `slack_list_all_channels` | List ALL channels (public + private) |
| `slack_find_channel` | Search for a channel by name |
| `slack_post_message` | Post a new message to a channel or DM |
| `slack_delete_message` | Delete messages |
| `slack_update_message` | Edit existing messages |
| `slack_get_channel_history_extended` | Read channel messages (inc. private) |
| `slack_get_thread_replies_extended` | Check thread replies |
| `slack_get_file` | Get file metadata and optionally image content (base64) from messages |

**Why this exists:** Cursor's built-in Slack MCP only lists public channels and has limited functionality. This MCP adds private channel support and message management.

---

## Setup Overview

| Step | Who | What |
|------|-----|------|
| 1 | Team Admin (once) | Create Slack App + get Bot Token |
| 2 | Each Developer | Install MCP + configure token |

---

## Part 1: Slack App Setup (Team Admin)

### Option A: Create App from Manifest (Recommended)

1. Go to https://api.slack.com/apps
2. Click **Create New App** → **From an app manifest**
3. Select your workspace
4. Paste this manifest (YAML tab):

```yaml
display_information:
  name: Cursor Chat
  description: Chat with Slack from Cursor IDE
  background_color: "#1a1a2e"
features:
  bot_user:
    display_name: Cursor
    always_online: true
oauth_config:
  scopes:
    bot:
      - chat:write
      - channels:read
      - channels:history
      - groups:read
      - groups:history
      - users:read
      - files:read
      - reactions:write
      - im:read
      - im:history
settings:
  org_deploy_enabled: false
  socket_mode_enabled: false
  token_rotation_enabled: false
```

5. Click **Create**
6. Go to **Install App** → **Install to Workspace**
7. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

### Option B: Create App Manually

1. Go to https://api.slack.com/apps → **Create New App** → **From scratch**
2. Name it "Cursor Chat" and select your workspace
3. Go to **OAuth & Permissions** → Add these **Bot Token Scopes**:

| Scope | Purpose |
|-------|---------|
| `chat:write` | Post, edit, delete messages |
| `channels:read` | List public channels |
| `channels:history` | Read public channel messages |
| `groups:read` | List private channels |
| `groups:history` | Read private channel messages |
| `users:read` | Look up users for @mentions |
| `files:read` | Read file metadata and content (e.g. images in messages) |
| `reactions:write` | Add emoji reactions |
| `im:read` | List DM conversations |
| `im:history` | Read DMs |

4. Click **Install to Workspace**
5. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

### Invite Bot to Private Channels

The bot can only see private channels it's been invited to:
1. Open the private channel in Slack
2. Click the channel name → **Integrations** → **Add apps**
3. Add "Cursor Chat"

---

## Part 2: Developer Setup (Each Person)

### Quick Install

```bash
curl -sL https://raw.githubusercontent.com/CanonSystems/cursor-slack-chat/main/setup.sh | bash
```

### Manual Install

```bash
git clone https://github.com/CanonSystems/cursor-slack-chat.git ~/.cursor/mcp-servers/cursor-slack-chat
cd ~/.cursor/mcp-servers/cursor-slack-chat
npm install
```

### Configure Cursor

Add to `~/.cursor/mcp.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "cursor-slack-chat": {
      "command": "node",
      "args": ["~/.cursor/mcp-servers/cursor-slack-chat/index.js"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-bot-token-here"
      }
    }
  }
}
```

**Important:** Replace `~` with your actual home directory path:
- macOS: `/Users/YOURNAME/.cursor/mcp-servers/cursor-slack-chat/index.js`
- Linux: `/home/YOURNAME/.cursor/mcp-servers/cursor-slack-chat/index.js`
- Windows: `C:\\Users\\YOURNAME\\.cursor\\mcp-servers\\cursor-slack-chat\\index.js`

### Restart Cursor

Quit and reopen Cursor to load the new MCP server.

---

## Part 3: Sharing the Bot Token with Your Team

The `SLACK_BOT_TOKEN` is sensitive. **Never commit it to a repo.**

### Recommended: Slack Workspace File

Store the token in a file within Slack itself:

1. Create a text file called `cursor-setup.txt` with:
   ```
   Cursor Slack Chat - Bot Token
   
   Token: xoxb-your-actual-token-here
   
   Setup:
   1. Run: curl -sL https://raw.githubusercontent.com/CanonSystems/cursor-slack-chat/main/setup.sh | bash
   2. Add the token above to ~/.cursor/mcp.json
   3. Restart Cursor
   ```

2. Upload it to a private channel (like #engineering or #dev-setup)
3. Pin the file so team members can find it easily

Team members can then access the token directly in Slack when they need it.

### Alternative Methods

- **Password manager** (1Password, LastPass) - Store in shared team vault
- **Private wiki** - Document in Confluence/Notion with restricted access
- **Direct share** - Team lead DMs the token to new members

---

## App Information

After creating your Slack App, you can find these IDs at https://api.slack.com/apps:

| Field | Where to Find | Example |
|-------|---------------|---------|
| **App ID** | Basic Information → App Credentials | `A0ACR01CGK0` |
| **Bot User ID** | OAuth & Permissions (in token response) | `U0ACLKBU7FD` |
| **Bot Token** | OAuth & Permissions → Bot User OAuth Token | `xoxb-xxx-xxx-xxx` |

---

## Usage Examples

Once configured, ask Cursor to:

```
List all Slack channels including private ones
```

```
Find the #showtrail channel
```

```
Send a message to Mani in #showtrail asking about the deployment
```

```
Check if anyone replied to my last message in #showtrail
```

```
Delete the message with timestamp 1770156144.483089 from channel C06QAJ35QPL
```

---

## Troubleshooting

### "Can't find private channels"
- Ensure `groups:read` scope is added
- Reinstall the app after adding scopes
- Invite the bot to the private channel

### "Missing scope" errors
- Check which scope is missing in the error
- Add it in OAuth & Permissions
- Reinstall the app to workspace

### Tools not appearing in Cursor
- Check `~/.cursor/mcp.json` syntax (valid JSON?)
- Verify the path to `index.js` is correct
- Restart Cursor completely (not just reload)

---

## Development

```bash
# Install dependencies
npm install

# Test locally
SLACK_BOT_TOKEN=xoxb-xxx node index.js
```

---

## License

MIT
