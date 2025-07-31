// This is our service worker (background script for Manifest V3).
// It's responsible for managing the side panel and communicating with the native host.

// Store a reference to the native messaging port
let nativeHostPort = null;
const nativeHostName = 'com.example.browser_console'; // IMPORTANT: Must match your native app's manifest name

// Function to connect to the native host if not already connected
async function connectToNativeHost() {
    if (nativeHostPort && !nativeHostPort.disconnected) {
        console.log("Native host port already open. Reusing existing connection."); // FIX: Removed file=sys.stderr
        return nativeHostPort;
    }

    try {
        console.log(`Attempting to connect to native host: "${nativeHostName}".`); // FIX: Removed file=sys.stderr
        nativeHostPort = chrome.runtime.connectNative(nativeHostName);

        // Listen for messages coming *from* the native host
        nativeHostPort.onMessage.addListener((responseFromNative) => {
            console.log("Received response from native host:", responseFromNative); // FIX: Removed file=sys.stderr
            // Send the native host's response back to the the specific sender (sidebar)
            chrome.runtime.sendMessage({ type: 'nativeHostResponse', payload: responseFromNative });
        });

        // Listener for when the native host disconnects
        nativeHostPort.onDisconnect.addListener(() => {
            if (chrome.runtime.lastError) {
                console.error("Native port disconnected unexpectedly:", chrome.runtime.lastError.message); // FIX: Removed file=sys.stderr
                // Inform the sidebar about the disconnection
                chrome.runtime.sendMessage({ type: 'nativeHostDisconnected', error: chrome.runtime.lastError.message });
            } else {
                console.log("Native port disconnected gracefully."); // FIX: Removed file=sys.stderr
                chrome.runtime.sendMessage({ type: 'nativeHostDisconnected', error: 'Graceful disconnect.' });
            }
            nativeHostPort = null; // Clear the reference
        });

        console.log("Native host connection established."); // FIX: Removed file=sys.stderr
        return nativeHostPort;

    } catch (e) {
        console.error("Error establishing native messaging connection:", e.message); // FIX: Removed file=sys.stderr
        // Inform the sidebar about the connection failure
        chrome.runtime.sendMessage({ type: 'nativeHostConnectionFailed', error: e.message });
        nativeHostPort = null;
        throw e; // Re-throw to handle in the message listener below
    }
}

// Listener for messages from the sidebar script (`sidebar.js`)
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type === 'executeNativeCommand') {
        const command = request.command;
        console.log(`Background script received command: "${command}".`); // FIX: Removed file=sys.stderr

        try {
            connectToNativeHost().then(port => {
                port.postMessage({ command: command });
            }).catch(error => {
                sendResponse({ error: `Failed to connect to native host: ${error.message}` });
            });
        } catch (e) {
            sendResponse({ error: `Failed to initiate connection: ${e.message}` });
        }
        return false;
    }
});


// Chrome Extension Side Panel API - ensure the side panel is always available for this extension
chrome.sidePanel
  .setPanelBehavior({ openPanelOnActionClick: true })
  .catch((error) => console.error(error));

// The problematic chrome.sidePanel.onPanelClosed.addListener block was removed in the previous step.