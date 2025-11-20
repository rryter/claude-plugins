#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

# Only process Bash tool calls
if tool_name != "Bash":
    sys.exit(0)

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

# For all other commands, don't interfere (normal permission flow)
sys.exit(0)
