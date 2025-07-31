#!/usr/bin/env python3
import sys
import json
import struct
import subprocess
import os
import datetime # Import for timestamping log file

# --- START DEBUG LOGGING TO FILE ---
# Define a log file path (e.g., in the same directory as your script)
log_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "native_host_debug.log")

try:
    # Open the log file in append mode. Use a timestamp to avoid overwriting previous runs easily.
    # Or 'w' (write) mode if you prefer to clear the log each time.
    # For now, let's use 'w' for fresh logs for debugging this issue.
    # You might switch to 'a' later.
    sys.stderr = open(log_file_path, 'a', encoding='utf-8')
    sys.stderr.write(f"--- Native Host Debug Session Started: {datetime.datetime.now()} ---\n")
    sys.stderr.flush() # Ensure this initial message is written
except Exception as e:
    # If logging fails, fall back to console stderr or just let it pass
    pass # If we can't open the log file, sys.stderr will remain the original stderr
# --- END DEBUG LOGGING TO FILE ---

# --- Helper Functions for Native Messaging Protocol ---
# (Keep get_message and send_message as they are)
def get_message():
    """Reads a message from stdin based on the native messaging protocol."""
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        sys.exit(0) # Browser disconnected or closed. Exit gracefully.
    message_length = struct.unpack('=I', raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode('utf-8')
    return json.loads(message)

def send_message(message_content):
    """Sends a message to stdout based on the native messaging protocol."""
    encoded_content = json.dumps(message_content, separators=(',', ':')).encode('utf-8')
    encoded_length = struct.pack('=I', len(encoded_content))
    sys.stdout.buffer.write(encoded_length)
    sys.stdout.buffer.write(encoded_content)
    sys.stdout.buffer.flush()

# --- Platform-specific setup for binary I/O ---
if sys.platform == "win32":
    try:
        import msvcrt
        msvcrt.setmode(sys.stdin.fileno(), os.O_BINARY)
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
    except ImportError:
        pass

# --- Command Execution Logic (keep this section as it was in the last full correct version) ---
def execute_shell_command(command, current_dir):
    # ... (your existing execute_shell_command function goes here, ensure it has the latest changes including `return_code` for cd) ...
    if sys.platform == "win32":
        if command.lower().startswith('cd '):
            new_dir_input = command[3:].strip()
            if not os.path.isabs(new_dir_input):
                new_dir_abs = os.path.join(current_dir, new_dir_input)
            else:
                new_dir_abs = new_dir_input

            try:
                resolved_new_dir = os.path.abspath(os.path.normpath(new_dir_abs))
                if os.path.isdir(resolved_new_dir):
                    print(f"DEBUG: Internal CD (in func): Path resolved to: {resolved_new_dir}", file=sys.stderr)
                    return {
                        "output": f"Directory changed to: {resolved_new_dir}",
                        "new_current_dir": resolved_new_dir,
                        "return_code": 0
                    }
                else:
                    return {"error": f"Directory not found: {new_dir_input} (Resolved to: {resolved_new_dir})", "return_code": 1}
            except Exception as e:
                return {"error": f"Error changing directory: {e}", "return_code": 1}

        full_command = f"cmd.exe /c \"{command}\""
    else: # Linux/macOS
        if command.lower().startswith('cd '):
            new_dir_input = command[3:].strip()
            if not os.path.isabs(new_dir_input):
                new_dir_abs = os.path.join(current_dir, new_dir_input)
            else:
                new_dir_abs = new_dir_input

            try:
                resolved_new_dir = os.path.abspath(os.path.normpath(new_dir_abs))
                if os.path.isdir(resolved_new_dir):
                    print(f"DEBUG: Internal CD (in func): Path resolved to: {resolved_new_dir}", file=sys.stderr)
                    return {
                        "output": f"Directory changed to: {resolved_new_dir}",
                        "new_current_dir": resolved_new_dir,
                        "return_code": 0
                    }
                else:
                    return {"error": f"Directory not found: {new_dir_input} (Resolved to: {resolved_new_dir})", "return_code": 1}
            except Exception as e:
                return {"error": f"Error changing directory: {e}", "return_code": 1}

        full_command = command

    try:
        print(f"DEBUG: Executing OS command: {full_command} in {current_dir}", file=sys.stderr)
        process = subprocess.run(
            full_command,
            shell=True,
            capture_output=True,
            text=True,
            check=False,
            cwd=current_dir,
            timeout=10
        )

        raw_output_lines = process.stdout.splitlines()
        filtered_output_lines = []

        ignore_patterns = [
            "c:\\users\\mark\\anaconda3\\condabin\\conda_hook.bat",
            "if exist",
            "call",
            "C:\\Users\\mark\\source\\browser\\BrowserConsole\\backend>" # Your observed prompt echo
        ]

        if command.lower() == 'whoami' or command.lower() == 'pwd':
            for line in reversed(raw_output_lines):
                line_lower = line.lower().strip()
                if line_lower and not any(p in line_lower for p in ignore_patterns):
                    filtered_output_lines = [line.strip()]
                    break
        else:
            for line in raw_output_lines:
                line_lower = line.lower().strip()
                if line_lower.startswith(current_dir.lower().replace('\\', '/') + ">") or \
                   line_lower.startswith("C:\\Users\\mark\\source\\browser\\BrowserConsole\\backend>"):
                    continue

                if any(p in line_lower for p in ignore_patterns):
                    continue

                if line.strip():
                    filtered_output_lines.append(line)

        response = {}
        if filtered_output_lines:
            response["output"] = "\n".join(filtered_output_lines).strip()
        else:
            if process.stdout.strip():
                response["output"] = "Command executed with noisy output filtered out."
            else:
                response["output"] = "Command executed with no output."

        if process.stderr:
            response["error"] = process.stderr.strip()
            if not response["output"] and not response["error"]:
                response["output"] = "Command executed with errors to stderr."

        response["return_code"] = process.returncode
        response["new_current_dir"] = current_dir
        return response

    except subprocess.TimeoutExpired:
        print(f"DEBUG: Command timed out: {command}", file=sys.stderr)
        return {
            "output": "",
            "error": "Command timed out after 10 seconds. It might be hanging.",
            "return_code": 1
        }
    except Exception as e:
        print(f"DEBUG: Error during command execution: {e}", file=sys.stderr)
        return {
            "output": "",
            "error": f"Failed to execute command: {e}",
            "return_code": 1
        }

# --- Main Loop (this is the most critical part for the CD fix) ---
def main():
    current_working_directory = os.getcwd()
    print(f"DEBUG: Native host initialized with CWD: {current_working_directory}", file=sys.stderr)

    while True:
        try:
            message = get_message()
            print(f"DEBUG: Received message: {message}", file=sys.stderr)
            command_to_execute = message.get('command', '').strip()

            # Initialize response_to_browser with the current directory
            response_to_browser = {
                "output": "",
                "error": "",
                "current_dir_for_browser": current_working_directory
            }

            # Handle internal `show_dir` command first
            if command_to_execute.lower() == 'show_dir':
                response_to_browser["output"] = f"Internal path: {current_working_directory}"
                send_message(response_to_browser)
                continue # Skip remaining logic for this command

            # Execute the command
            result_from_execution = execute_shell_command(command_to_execute, current_working_directory)
            print(f"DEBUG: Result from execute_shell_command: {result_from_execution}", file=sys.stderr)

            # Update current_working_directory *only if* it was a successful 'cd' operation
            # The 'new_current_dir' key should be present and return_code should be 0 for a successful cd.
            if result_from_execution.get("return_code") == 0 and 'new_current_dir' in result_from_execution:
                old_cwd = current_working_directory
                current_working_directory = result_from_execution['new_current_dir']
                print(f"DEBUG: CWD **UPDATED** from '{old_cwd}' to '{current_working_directory}'", file=sys.stderr)
                # Ensure a clear output message for the browser for successful CD
                if not result_from_execution.get("output"):
                     response_to_browser["output"] = f"Directory changed to: {current_working_directory}"
                else:
                     response_to_browser["output"] = result_from_execution["output"]
            else:
                # For non-CD commands or failed commands, just transfer output/error
                if 'output' in result_from_execution:
                    response_to_browser['output'] = result_from_execution['output']
                if 'error' in result_from_execution:
                    response_to_browser['error'] = result_from_execution['error']


            # IMPORTANT: Always ensure the 'current_dir_for_browser' reflects the *latest* CWD
            response_to_browser['current_dir_for_browser'] = current_working_directory
            print(f"DEBUG: Final response to browser: {response_to_browser}", file=sys.stderr)

            send_message(response_to_browser)

        except json.JSONDecodeError as e:
            print(f"Native host JSON decode error: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Native host general error: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()