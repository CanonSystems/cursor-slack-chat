# Cursor Slack Chat

Chat with your team on Slack directly from Cursor. Message team members and channels as things come up during development.

## Features

- `slack_delete_message` - Delete messages from channels or DMs
- `slack_update_message` - Edit existing messages  
- `slack_get_thread_replies` - Check if someone replied to your message
- `slack_get_channel_history` - See recent messages in a channel
- `slack_list_all_channels` - List ALL channels (public + private the bot is in)
- `slack_find_channel` - Find a channel by name and get its ID

## Quick Install

```bash
curl -sL https://raw.githubusercontent.com/familyoneInc/cursor-slack-chat/main/setup.sh | bash
```

Or manually:
```bash
git clone https://github.com/familyoneInc/cursor-slack-chat.git ~/.cursor/mcp-servers/cursor-slack-chat
cd ~/.cursor/mcp-servers/cursor-slack-chat
npm install
```

## Configuration

Add to your `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "cursor-slack-chat": {
      "command": "node",
      "args": ["/Users/YOURNAME/.cursor/mcp-servers/cursor-slack-chat/index.js"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-bot-token"
      }
    }
  }
}
```

Then restart Cursor.

## Team Setup

**The team shares ONE Slack bot.** Each person:
1. Runs the install script
2. Uses the same shared `SLACK_BOT_TOKEN` in their config
3. Restarts Cursor

## Required Slack Bot Permissions

Your Slack bot token needs these OAuth scopes:

| Scope | Purpose |
|-------|---------|
| `chat:write` | Post, edit, and delete messages |
| `channels:history` | Read messages in public channels |
| `channels:read` | List public channels |
| `groups:history` | Read messages in private channels |
| `groups:read` | List private channels the bot is in |
| `im:history` | Read direct messages |
| `im:read` | List DM conversations |
| `reactions:write` | Add emoji reactions |
| `users:read` | Look up user info |

### Adding scopes
1. Go to https://api.slack.com/apps
2. Select your app → **OAuth & Permissions**
3. Add scopes under **Bot Token Scopes**
4. **Reinstall** the app to your workspace

## Sharing the Bot Token with Your Team

The `SLACK_BOT_TOKEN` is sensitive. **Never commit it to a repo.**

### Recommended: Slack Slash Command
Set up a `/cursor-setup` slash command in Slack that responds with the token and setup instructions. This way team members can self-serve directly in Slack.

### Alternative Methods
- **Password manager** (1Password, LastPass) - Store in a shared team vault
- **Private wiki** - Document in Confluence/Notion with restricted access
- **Direct share** - Team lead DMs the token to new members

### Environment Variables
Store the token in your shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
export SLACK_BOT_TOKEN="xoxb-your-token"
```

Then reference it in `mcp.json`:
```json
"env": {
  "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}"
}
```
Note: Cursor may not expand env vars in mcp.json - test this first.

## Usage

Once configured, Cursor can use these tools:

### Delete a message
```
Delete the message in channel C06QAJ35QPL with timestamp 1770156144.483089
```

## Development

```bash
# Install dependencies
npm install

# Test locally
SLACK_BOT_TOKEN=xoxb-xxx node index.js
```

## License

MIT
