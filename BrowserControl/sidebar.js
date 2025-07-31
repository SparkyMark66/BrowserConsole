const outputDiv = document.getElementById('console-output');
const commandInput = document.getElementById('command-input');
const promptSpan = document.getElementById('prompt');

let commandHistory = [];
let historyIndex = -1;

// NEW: Variable to hold the reference to the last 'awaiting' message element
let lastAwaitingMessageElement = null;

function appendToOutput(text, className = 'output-line') {
    const line = document.createElement('div');
    line.classList.add(className);
    line.textContent = text;
    outputDiv.appendChild(line);
    outputDiv.scrollTop = outputDiv.scrollHeight;
    return line; // Return the created element
}

// Listener for messages coming from the background script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type === 'nativeHostResponse') {
        // NEW: Remove the previous 'awaiting' message if it exists
        if (lastAwaitingMessageElement && lastAwaitingMessageElement.parentNode) {
            lastAwaitingMessageElement.parentNode.removeChild(lastAwaitingMessageElement);
            lastAwaitingMessageElement = null; // Clear the reference
        }

        const response = request.payload;
        if (response.output) {
            appendToOutput(response.output);
        }
        if (response.error) {
            appendToOutput(`Error: ${response.error}`, 'error-line');
        } else if (!response.output) {
            // If there's no output and no error, explicitly state command executed
            appendToOutput("Command executed with no output.");
        }

        // Update browser prompt if new_current_dir is provided
        if (response.current_dir_for_browser) {
            let displayPath = response.current_dir_for_browser;
            const maxLength = 30;
            if (displayPath.length > maxLength) {
                const lastSeparator = Math.max(displayPath.lastIndexOf('\\'), displayPath.lastIndexOf('/'));
                if (lastSeparator > displayPath.length - maxLength + 5) {
                    displayPath = '...' + displayPath.substring(lastSeparator);
                } else {
                     displayPath = '...' + displayPath.substring(displayPath.length - maxLength);
                }
            }
            promptSpan.textContent = `${displayPath}>`;
        }
    } else if (request.type === 'nativeHostDisconnected' || request.type === 'nativeHostConnectionFailed') {
        // NEW: Also remove 'awaiting' message if connection fails/disconnects
        if (lastAwaitingMessageElement && lastAwaitingMessageElement.parentNode) {
            lastAwaitingMessageElement.parentNode.removeChild(lastAwaitingMessageElement);
            lastAwaitingMessageElement = null;
        }
        appendToOutput(`Native host status: ${request.error}. Some commands may not work.`, 'error-line');
    }
});


commandInput.addEventListener('keydown', function(event) {
    if (event.key === 'Enter') {
        event.preventDefault();
        const command = commandInput.value.trim();
        if (command) {
            appendToOutput(promptSpan.textContent + command, 'command-line');
            if (commandHistory.length === 0 || commandHistory[0] !== command) {
                commandHistory.unshift(command);
            }
            historyIndex = -1;
            executeCommand(command);
        }
        commandInput.value = '';
    } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        if (commandHistory.length > 0 && historyIndex < commandHistory.length - 1) {
            historyIndex++;
            commandInput.value = commandHistory[historyIndex];
            setTimeout(() => commandInput.setSelectionRange(commandInput.value.length, commandInput.value.length), 0);
        }
    } else if (event.key === 'ArrowDown') {
        event.preventDefault();
        if (historyIndex > -1) {
            historyIndex--;
            if (historyIndex === -1) {
                commandInput.value = '';
            } else {
                commandInput.value = commandHistory[historyIndex];
            }
            setTimeout(() => commandInput.setSelectionRange(commandInput.value.length, commandInput.value.length), 0);
        }
    }
});

async function executeCommand(command) {
    // Internal Browser-Side Commands
    if (command.toLowerCase() === 'clear') {
        outputDiv.innerHTML = '';
        return;
    }
    if (command.toLowerCase() === 'help') {
        outputDiv.innerHTML = ''; // Clear for help
        appendToOutput(' ');
        appendToOutput(' ');
        appendToOutput('Available commands:');
        appendToOutput('  clear   - Clears the console output.');
        appendToOutput('  help    - Displays this help message.');
        appendToOutput('  echo <text> - Prints the given text.');
        appendToOutput('  show_dir - Displays the backend path variable.');
        appendToOutput(' ');
        appendToOutput('Native OS commands will be executed if the companion native application is installed.');
        return;
    }
    if (command.toLowerCase().startsWith('echo ')) {
        appendToOutput(command.substring(5));
        return;
    }

    // Send command to Background Script for Native Execution
    try {
        // NEW: Store the reference to the 'awaiting' message
        lastAwaitingMessageElement = appendToOutput('... (awaiting native response)', 'info-line');
        chrome.runtime.sendMessage({ type: 'executeNativeCommand', command: command });
    } catch (e) {
        // If message sending itself fails, clear the 'awaiting' message immediately
        if (lastAwaitingMessageElement && lastAwaitingMessageElement.parentNode) {
            lastAwaitingMessageElement.parentNode.removeChild(lastAwaitingMessageElement);
            lastAwaitingMessageElement = null;
        }
        appendToOutput(`Error sending command to background: ${e.message}`, 'error-line');
    }
}

// Initial setup on sidebar load
window.addEventListener('load', () => {
    commandInput.focus();
    appendToOutput(' >');
    appendToOutput(' ');
    appendToOutput('Type "help" for a list of internal commands.');
    appendToOutput('Native commands require the companion app.');
    // Optional: Send an initial 'pwd' or 'show_dir' to update prompt on load
    // executeCommand('show_dir'); // You could uncomment this for an initial path display
});