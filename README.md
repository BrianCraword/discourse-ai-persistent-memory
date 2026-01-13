# Discourse AI Persistent Memory

A Discourse plugin that enables persistent memory for AI personas, allowing them to remember user-specific information across conversations.

## Features

- **Persistent Storage**: AI personas can save and retrieve user memories that persist across conversations
- **User Management UI**: Users can view, add, and delete their memories in preferences
- **Key/Value Storage**: Simple key/value pairs stored per user
- **No Core Modifications**: Uses module prepend to inject into ToolRunner without modifying discourse-ai

## Requirements

- Discourse (latest)
- [discourse-ai](https://github.com/discourse/discourse-ai) plugin

## Installation

Add to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/BrianCraword/discourse-ai-persistent-memory.git
```

Then rebuild:

```bash
./launcher rebuild app
```

## Setup

### 1. Create the AI Tool

Go to **Admin → AI → Tools → New Tool** and create a tool with:

**Name:** `memory`

**Script:**
```javascript
function invoke(params) {
  const action = params.action;
  const key = params.key;
  const value = params.value;

  if (action === "set") {
    if (!key || !value) return { error: "Key and value required" };
    return memory.set(key, value);
  } else if (action === "get") {
    if (!key) return { error: "Key required" };
    return { value: memory.get(key) };
  } else if (action === "list") {
    return { memories: memory.list() };
  } else if (action === "delete") {
    if (!key) return { error: "Key required" };
    return memory.delete(key);
  }
  return { error: "Invalid action" };
}
```

**Parameters:**
- `action` (string, required): One of "set", "get", "list", "delete"
- `key` (string): The memory key
- `value` (string): The value to store (for set action)

### 2. Enable on Persona

Edit your persona and:
1. Add the `memory` tool to enabled tools
2. Add instructions to the system prompt, e.g.:

```
You have access to a memory tool to remember user preferences and information.
- Use memory.set(key, value) to remember something
- Use memory.get(key) to recall something
- Use memory.list() to see all memories for this user
- Use memory.delete(key) to forget something

Proactively save important user preferences when they mention them.
```

## User Interface

Users can view and manage their memories at:
`/u/{username}/preferences/interface`

## How It Works

1. The plugin injects memory functions into discourse-ai's ToolRunner via `prepend`
2. Memories are stored in Discourse's PluginStore with namespace `ai_user_memory_{user_id}`
3. The AI tool provides a JavaScript interface to these functions
4. All memories are loaded into context (not selective retrieval)

## Limitations

- Loads ALL user memories into context (may use more tokens with many memories)
- No semantic search (keyword-based only)
- Requires manual tool configuration

## Disclaimer

**This plugin was created with AI assistance. The author is not a programmer and cannot provide support.** 

Use at your own risk. Contributions and improvements welcome!

## License

MIT
