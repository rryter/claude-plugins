#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

# Handle Bash tool calls
if tool_name == "Bash":
    command = tool_input.get("command", "")
    # Auto-approve commands that run scripts from the plugin directory
    if "bash ${CLAUDE_PLUGIN_ROOT}/scripts/" in command:
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Plugin script auto-approved"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

# Handle Write tool calls to /tmp/
if tool_name == "Write":
    file_path = tool_input.get("file_path", "")
    if file_path.startswith("/tmp/"):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Write to /tmp/ auto-approved for plugin workflow"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

# For all other commands, don't interfere (normal permission flow)
sys.exit(0)
