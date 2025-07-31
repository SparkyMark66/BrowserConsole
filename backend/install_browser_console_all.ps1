# This PowerShell script checks for the native messaging host manifest file
# in the current directory, updates its internal 'path' to the native host executable,
# and then registers it with Chrome's, Edge's, and Firefox's Native Messaging hosts
# in the HKEY_CURRENT_USER registry hive.

# --- Configuration ---
$nativeHostName = "com.example.browser_console"
$manifestFileName = "$nativeHostName.json"
$executableFileName = "run_native_host.bat" # The script that launches your Python host

# Registry paths for different browsers on Windows
$chromeRegistryPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts"
$edgeRegistryPath = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts"
$firefoxRegistryPath = "HKCU:\Software\Mozilla\NativeMessagingHosts" # NEW: Firefox Registry Path

# --- Get Script's Current Directory ---
$scriptDir = $PSScriptRoot

# --- Construct Full Paths ---
$fullManifestPath = Join-Path -Path $scriptDir -ChildPath $manifestFileName
$fullExecutablePath = Join-Path -Path $scriptDir -ChildPath $executableFileName

Write-Host "--- Native Messaging Host Registration Script (Enhanced for All Common Browsers) ---"
Write-Host "Expected manifest file: $fullManifestPath"
Write-Host "Expected executable file: $fullExecutablePath"

# --- Check if the Manifest File Exists ---
if (Test-Path $fullManifestPath -PathType Leaf) {
    Write-Host "Manifest file '$manifestFileName' found."

    # --- Read, Update, and Write the Manifest JSON ---
    Write-Host "Updating internal path in '$manifestFileName' to point to '$fullExecutablePath'..."
    try {
        $manifestContent = Get-Content -Path $fullManifestPath -Raw | ConvertFrom-Json

        if ($IsWindows) {
            $manifestContent.path = $fullExecutablePath.Replace('\', '\\')
        } else {
            $manifestContent.path = $fullExecutablePath
        }

        # NOTE: For cross-browser compatibility, ensure your com.example.browser_console.json
        # uses 'allowed_origins' for Chrome/Edge and 'allowed_extensions' for Firefox.
        # This script only updates the 'path' field. The 'allowed_origins'/'allowed_extensions'
        # array must be manually configured in the JSON file based on your extension IDs.

        $manifestContent | ConvertTo-Json -Depth 100 | Set-Content -Path $fullManifestPath -Encoding UTF8 -Force

        Write-Host "Internal manifest path updated successfully."
    }
    catch {
        Write-Error "Failed to read, update, or write manifest file: $_"
        Write-Host "Please ensure the manifest file is valid JSON and writable."
        exit 1
    }

    # --- Register for Google Chrome ---
    Write-Host "`n--- Registering for Google Chrome ---"
    try {
        Write-Host "Ensuring Chrome registry path '$chromeRegistryPath' exists..."
        New-Item -Path $chromeRegistryPath -ErrorAction Stop -Force | Out-Null
        Write-Host "Chrome registry path ensured."

        Write-Host "Registering native host '$nativeHostName' for Chrome..."
        New-Item -Path "$chromeRegistryPath\$nativeHostName" -ErrorAction Stop -Force | Out-Null
        Set-ItemProperty -LiteralPath "$chromeRegistryPath\$nativeHostName" -Name "(Default)" -Value $fullManifestPath -ErrorAction Stop

        Write-Host "Successfully registered for Chrome."
    }
    catch {
        Write-Error "Failed to register for Chrome: $_"
        Write-Host "Please ensure you have sufficient permissions."
    }

    # --- Register for Microsoft Edge ---
    Write-Host "`n--- Registering for Microsoft Edge ---"
    try {
        Write-Host "Ensuring Edge registry path '$edgeRegistryPath' exists..."
        New-Item -Path $edgeRegistryPath -ErrorAction Stop -Force | Out-Null
        Write-Host "Edge registry path ensured."

        Write-Host "Registering native host '$nativeHostName' for Edge..."
        New-Item -Path "$edgeRegistryPath\$nativeHostName" -ErrorAction Stop -Force | Out-Null
        Set-ItemProperty -LiteralPath "$edgeRegistryPath\$nativeHostName" -Name "(Default)" -Value $fullManifestPath -ErrorAction Stop

        Write-Host "Successfully registered for Edge."
    }
    catch {
        Write-Error "Failed to register for Edge: $_"
        Write-Host "Please ensure you have sufficient permissions."
    }

    # --- Register for Mozilla Firefox ---
    Write-Host "`n--- Registering for Mozilla Firefox ---"
    try {
        Write-Host "Ensuring Firefox registry path '$firefoxRegistryPath' exists..."
        New-Item -Path $firefoxRegistryPath -ErrorAction Stop -Force | Out-Null
        Write-Host "Firefox registry path ensured."

        Write-Host "Registering native host '$nativeHostName' for Firefox..."
        New-Item -Path "$firefoxRegistryPath\$nativeHostName" -ErrorAction Stop -Force | Out-Null
        Set-ItemProperty -LiteralPath "$firefoxRegistryPath\$nativeHostName" -Name "(Default)" -Value $fullManifestPath -ErrorAction Stop

        Write-Host "Successfully registered for Firefox."
    }
    catch {
        Write-Error "Failed to register for Firefox: $_"
        Write-Host "Please ensure you have sufficient permissions."
    }

    Write-Host "`nRemember to restart all browsers for changes to take effect."
} else {
    Write-Warning "Manifest file '$manifestFileName' NOT found in '$scriptDir'."
    Write-Warning "Please ensure the script is run from the directory containing '$manifestFileName'."
    exit 1
}

Write-Host "--- Script Finished ---"
