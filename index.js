#!/usr/bin/env node

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");

const botToken = process.env.SLACK_BOT_TOKEN;

const headers = {
  Authorization: `Bearer ${botToken}`,
  "Content-Type": "application/json",
};

// Slack API helpers
async function deleteMessage(channel_id, ts) {
  const response = await fetch("https://slack.com/api/chat.delete", {
    method: "POST",
    headers,
    body: JSON.stringify({ channel: channel_id, ts }),
  });
  return response.json();
}

async function updateMessage(channel_id, ts, text) {
  const response = await fetch("https://slack.com/api/chat.update", {
    method: "POST",
    headers,
    body: JSON.stringify({ channel: channel_id, ts, text }),
  });
  return response.json();
}

async function getThreadReplies(channel_id, thread_ts) {
  const params = new URLSearchParams({
    channel: channel_id,
    ts: thread_ts,
  });
  const response = await fetch(
    `https://slack.com/api/conversations.replies?${params}`,
    { headers }
  );
  return response.json();
}

async function getChannelHistory(channel_id, limit = 10) {
  const params = new URLSearchParams({
    channel: channel_id,
    limit: limit.toString(),
  });
  const response = await fetch(
    `https://slack.com/api/conversations.history?${params}`,
    { headers }
  );
  return response.json();
}

async function listAllChannels(limit = 200, types = "public_channel,private_channel") {
  const params = new URLSearchParams({
    types: types,
    exclude_archived: "true",
    limit: Math.min(limit, 1000).toString(),
  });
  const response = await fetch(
    `https://slack.com/api/conversations.list?${params}`,
    { headers }
  );
  return response.json();
}

async function findChannelByName(name) {
  // Search in public and private channels
  const result = await listAllChannels(1000);
  if (!result.ok) return result;
  
  const searchName = name.toLowerCase().replace(/^#/, '');
  const channel = result.channels.find(ch => 
    ch.name.toLowerCase() === searchName ||
    ch.name.toLowerCase().includes(searchName)
  );
  
  if (channel) {
    return { ok: true, channel };
  }
  return { ok: false, error: "channel_not_found", searched: searchName };
}

// Tool definitions
const tools = [
  {
    name: "slack_delete_message",
    description: "Delete a message from a Slack channel or DM",
    inputSchema: {
      type: "object",
      properties: {
        channel_id: {
          type: "string",
          description: "The ID of the channel/DM containing the message",
        },
        ts: {
          type: "string",
          description: "The timestamp (ts) of the message to delete (e.g., '1234567890.123456')",
        },
      },
      required: ["channel_id", "ts"],
    },
  },
  {
    name: "slack_update_message",
    description: "Update/edit an existing message in a Slack channel or DM",
    inputSchema: {
      type: "object",
      properties: {
        channel_id: {
          type: "string",
          description: "The ID of the channel/DM containing the message",
        },
        ts: {
          type: "string",
          description: "The timestamp (ts) of the message to update (e.g., '1234567890.123456')",
        },
        text: {
          type: "string",
          description: "The new text content for the message",
        },
      },
      required: ["channel_id", "ts", "text"],
    },
  },
  {
    name: "slack_get_thread_replies",
    description: "Get all replies to a message thread. Use this to check if someone replied to a message you posted.",
    inputSchema: {
      type: "object",
      properties: {
        channel_id: {
          type: "string",
          description: "The ID of the channel containing the thread",
        },
        thread_ts: {
          type: "string",
          description: "The timestamp of the parent message (the message you want to check replies for)",
        },
      },
      required: ["channel_id", "thread_ts"],
    },
  },
  {
    name: "slack_get_channel_history",
    description: "Get recent messages from a channel. Use this to see recent activity or find messages.",
    inputSchema: {
      type: "object",
      properties: {
        channel_id: {
          type: "string",
          description: "The ID of the channel",
        },
        limit: {
          type: "number",
          description: "Number of messages to retrieve (default 10, max 100)",
          default: 10,
        },
      },
      required: ["channel_id"],
    },
  },
  {
    name: "slack_list_all_channels",
    description: "List ALL channels including private channels the bot is a member of. Returns channel names and IDs.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum number of channels to return (default 200, max 1000)",
          default: 200,
        },
        types: {
          type: "string",
          description: "Comma-separated channel types: public_channel, private_channel, mpim, im (default: public_channel,private_channel)",
          default: "public_channel,private_channel",
        },
      },
    },
  },
  {
    name: "slack_find_channel",
    description: "Find a channel by name (searches both public and private channels). Returns the channel ID if found.",
    inputSchema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "The channel name to search for (with or without #)",
        },
      },
      required: ["name"],
    },
  },
];

// Tool handlers
async function handleToolCall(name, args) {
  switch (name) {
    case "slack_delete_message": {
      const { channel_id, ts } = args;
      if (!channel_id || !ts) {
        throw new Error("Missing required arguments: channel_id and ts");
      }
      return await deleteMessage(channel_id, ts);
    }
    case "slack_update_message": {
      const { channel_id, ts, text } = args;
      if (!channel_id || !ts || !text) {
        throw new Error("Missing required arguments: channel_id, ts, and text");
      }
      return await updateMessage(channel_id, ts, text);
    }
    case "slack_get_thread_replies": {
      const { channel_id, thread_ts } = args;
      if (!channel_id || !thread_ts) {
        throw new Error("Missing required arguments: channel_id and thread_ts");
      }
      return await getThreadReplies(channel_id, thread_ts);
    }
    case "slack_get_channel_history": {
      const { channel_id, limit } = args;
      if (!channel_id) {
        throw new Error("Missing required argument: channel_id");
      }
      return await getChannelHistory(channel_id, limit || 10);
    }
    case "slack_list_all_channels": {
      const { limit, types } = args;
      return await listAllChannels(limit || 200, types || "public_channel,private_channel");
    }
    case "slack_find_channel": {
      const { name } = args;
      if (!name) {
        throw new Error("Missing required argument: name");
      }
      return await findChannelByName(name);
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

async function main() {
  if (!botToken) {
    console.error("Error: SLACK_BOT_TOKEN environment variable is required");
    process.exit(1);
  }

  const server = new Server(
    { name: "Cursor Slack Chat", version: "1.0.0" },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler({ method: "tools/list" }, async () => ({
    tools,
  }));

  server.setRequestHandler({ method: "tools/call" }, async (request) => {
    const { name, arguments: args } = request.params;
    try {
      const response = await handleToolCall(name, args);
      return { content: [{ type: "text", text: JSON.stringify(response) }] };
    } catch (error) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }) }],
      };
    }
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Server Slack Extended running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
