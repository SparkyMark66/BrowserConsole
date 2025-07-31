# This PowerShell script checks for the native messaging host manifest file
# in the current directory, updates its internal 'path' to the native host executable,
# and then registers it with Chrome's Native Messaging hosts in the HKEY_CURRENT_USER registry hive.

# --- Configuration ---
$nativeHostName = "com.example.browser_console"
$manifestFileName = "$nativeHostName.json"
$executableFileName = "run_native_host.bat" # The script that launches your Python host
$chromeRegistryPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts"
$targetRegistryKey = "$chromeRegistryPath\$nativeHostName"

# --- Get Script's Current Directory ---
# $PSScriptRoot holds the directory from which the script is being executed.
$scriptDir = $PSScriptRoot

# --- Construct Full Paths ---
$fullManifestPath = Join-Path -Path $scriptDir -ChildPath $manifestFileName
$fullExecutablePath = Join-Path -Path $scriptDir -ChildPath $executableFileName

Write-Host "--- Native Messaging Host Registration Script (Enhanced) ---"
Write-Host "Expected manifest file: $fullManifestPath"
Write-Host "Expected executable file: $fullExecutablePath"

# --- Check if the Manifest File Exists ---
if (Test-Path $fullManifestPath -PathType Leaf) {
    Write-Host "Manifest file '$manifestFileName' found."

    # --- Read, Update, and Write the Manifest JSON ---
    Write-Host "Updating internal path in '$manifestFileName' to point to '$fullExecutablePath'..."
    try {
        # Read the JSON content
        $manifestContent = Get-Content -Path $fullManifestPath -Raw | ConvertFrom-Json

        # Update the 'path' property to the current absolute path of the executable
        # Ensure correct path separators for JSON (forward slashes or double backslashes)
        if ($IsWindows) {
            $manifestContent.path = $fullExecutablePath.Replace('\', '\\')
        } else {
            $manifestContent.path = $fullExecutablePath # For non-Windows, usually forward slashes are fine
        }

        # Convert back to JSON and write to file
        $manifestContent | ConvertTo-Json -Depth 100 | Set-Content -Path $fullManifestPath -Encoding UTF8 -Force

        Write-Host "Internal manifest path updated successfully."
    }
    catch {
        Write-Error "Failed to read, update, or write manifest file: $_"
        Write-Host "Please ensure the manifest file is valid JSON and writable."
        exit 1
    }

    # --- Ensure the Parent Registry Path Exists ---
    Write-Host "Ensuring registry path '$chromeRegistryPath' exists..."
    try {
        New-Item -Path $chromeRegistryPath -ErrorAction Stop -Force | Out-Null
        Write-Host "Registry path ensured."
    }
    catch {
        Write-Error "Failed to create or ensure registry path: $_"
        Write-Host "Please ensure you have sufficient permissions to write to the registry."
        exit 1
    }

    # --- Create or Update the Native Host Registry Key ---
    Write-Host "Registering native host '$nativeHostName' in registry..."
    try {
        # Create the key if it doesn't exist, or get it if it does
        $key = New-Item -Path $targetRegistryKey -ErrorAction Stop -Force

        # Set the default (unnamed) value of the key to the full manifest path
        Set-ItemProperty -LiteralPath $targetRegistryKey -Name "(Default)" -Value $fullManifestPath -ErrorAction Stop

        Write-Host "Successfully registered native messaging host '$nativeHostName'."
        Write-Host "Manifest path set to: $fullManifestPath"
        Write-Host "Remember to restart Chrome for changes to take effect."
    }
    catch {
        Write-Error "Failed to register native host in registry: $_"
        Write-Host "Please ensure you have sufficient permissions to write to the registry."
        exit 1
    }
} else {
    Write-Warning "Manifest file '$manifestFileName' NOT found in '$scriptDir'."
    Write-Warning "Please ensure the script is run from the directory containing '$manifestFileName'."
    exit 1
}

Write-Host "--- Script Finished ---"
