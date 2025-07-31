# **🚀 Unleash Your Browser's Inner Command Prompt\! 🚀**

Ever wished you could run system commands directly from your browser's sidebar? Well, your wish just came true\! Introducing the **Browser Console Extension** – a super cool tool that brings a familiar command-line interface right into your favorite web browser.

![Alt text](./Screensho.png??raw=true "Screen Shot")

## **🌟 What Does This Magical Extension Do?**

Imagine having a mini Windows-style command prompt living in your browser's side panel. That's exactly what this extension delivers\!

* **Familiar Interface:** It looks and feels just like a classic command prompt, complete with a blinking cursor and a customizable prompt.  
* **Internal Commands:** It supports basic commands like help, clear, show\_dir, and echo right within the browser.  
* **Native System Commands:** This is where the real magic happens\! Thanks to a clever "Native Messaging Host" (a little helper app running on your computer), you can execute *actual operating system commands* like dir, pwd, whoami, ipconfig, and even navigate your file system with cd.  
* **Persistent Session:** Unlike a fleeting popup, this console lives in your sidebar, maintaining its state (like your current directory\!) as you browse.

## **✨ Possible Uses – Beyond Just "Cool"\!**

While it's undeniably cool, this extension isn't just for show. Think of the possibilities:

* **Quick System Checks:** Need to quickly check your IP address (ipconfig / ip a) or see what files are in a directory (dir / ls) without leaving your browser? Done\!  
* **Developer's Sidekick:** For web developers, quickly run build scripts, check environment variables, or even trigger local server commands without switching windows.  
* **Learning & Experimentation:** A safe and accessible way to learn basic command-line operations without opening a separate terminal.  
* **Productivity Boost:** Keep your focus in one place – your browser – while still having powerful system access at your fingertips. Originally built to allow me to ‘Vibe Code’ directly in my browser whilst interacting with a LLM. Specifically using my Python implementation Touch (touchp   
* \[Link Text\]([https://github.com/SparkyMark66/TouchP](https://github.com/SparkyMark66/TouchP)) is an implementation of touch with a following paste operation. So the text in the clipboard can be saved to the filesystem from the browser, and also run from within the browser.

## **📦 How to Get This Awesome Extension (from GitHub)**

Ready to dive in? Here's how to grab all the source files from GitHub:

1. **Head to the GitHub Repository:**  
   * (Imagine a screenshot here of a GitHub repo page with the "Code" button highlighted)  
2. **Download the Code:**  
   * On the main page of the repository, look for the green **\< \> Code** button.  
   * Click on it, and then select **Download ZIP** from the dropdown menu.  
   * Save the .zip file to your computer.  
3. **Extract the Files:**  
   * Once downloaded, locate the .zip file (e.g., Browser-Add-in-main.zip).  
   * Right-click on it and choose **"Extract All..."** (or similar option depending on your operating system).  
   * Choose a convenient location on your computer to extract the files. This will create a main folder (e.g., Browser-Add-in-main).

## **🛠️ Setting It Up – Let's Get This Console Running\!**

After extracting the files, you'll have a directory structure like this:

Browser-Add-in-main/  
├── BrowserControl/      \<-- Your Browser Extension Files  
│   ├── manifest.json  
│   ├── sidebar.html  
│   ├── ... (other extension files)  
│   └── icons/  
│  
└── backend/             \<-- Your Native Host Files  
    ├── native\_host.py  
    ├── run\_native\_host.bat  
    ├── com.example.browser\_console.json  
    └── install\_native\_host.ps1

Let's get everything configured\!

### **Step 1: Prerequisites – What You Need**

Before we start, make sure you have these installed:

* Python 3: The native host runs on Python. Download and install the latest version from python.org. Make sure to check the "Add Python to PATH" option during installation\!  
  \*  
* **PowerShell (Windows):** The setup script is a PowerShell script. Windows 10/11 usually has this pre-installed.

### **Step 2: Load the Browser Extension**

You'll need to load the extension into each browser you want to use it with.

#### **🌐 For Google Chrome:**

1. **Open Extensions Page:**  
   * Open Chrome and type chrome://extensions/ into the address bar, then press Enter.  
2. **Enable Developer Mode:**  
   * In the top-right corner, toggle on **"Developer mode"**.  
3. **Load Unpacked:**  
   * Click the **"Load unpacked"** button that appears.  
   * Navigate to your extracted project folder, then select the **BrowserControl** folder (e.g., C:\\YourPath\\Browser-Add-in-main\\BrowserControl).  
   * Click **"Select Folder"**.  
4. **Copy Extension ID:**  
   * Your "Browser Console" extension will now appear. **Copy its ID** (a long string of characters) from its card. You'll need this for the next step\!

#### **🚀 For Microsoft Edge:**

1. **Open Extensions Page:**  
   * Open Edge and type edge://extensions/ into the address bar, then press Enter.  
2. **Enable Developer Mode:**  
   * In the bottom-left corner, toggle on **"Developer mode"**.  
3. **Load Unpacked:**  
   * Click the **"Load unpacked"** button.  
   * Navigate to your extracted project folder, then select the **BrowserControl** folder (e.g., C:\\YourPath\\Browser-Add-in-main\\BrowserControl).  
   * Click **"Select Folder"**.  
4. **Copy Extension ID:**  
   * Your "Browser Console" extension will now appear. **Copy its ID** from its card. This will be different from your Chrome ID\!

#### **🦊 For Mozilla Firefox:**

1. **Open Debugging Page:**  
   * Open Firefox and type about:debugging\#/runtime/this-firefox into the address bar, then press Enter.  
2. **Load Temporary Add-on:**  
   * Click the **"Load Temporary Add-on..."** button.  
   * Navigate to your extracted project folder, then go into the **BrowserControl** folder (e.g., C:\\YourPath\\Browser-Add-in-main\\BrowserControl).  
   * Select the **manifest.json** file inside BrowserControl.  
3. **Note Extension ID:**  
   * Firefox assigns a temporary ID (e.g., webextension@temporary-addon). If you added browser\_specific\_settings to your manifest.json with a specific id (like browser\_console@yourdomain.com), that's the ID you'll use. Otherwise, use the temporary one for testing.

### **Step 3: Configure the Native Host Manifest (com.example.browser\_console.json)**

This is the most critical step for allowing your browser extension to talk to the Python backend.

1. **Locate the Manifest File:**  
   * Navigate to the backend folder in your extracted project (e.g., C:\\YourPath\\Browser-Add-in-main\\backend).  
   * Open the file named com.example.browser\_console.json in a text editor (like Notepad, VS Code, etc.).  
2. **Add Your Extension IDs:**  
   * Inside this JSON file, you'll see an array called "allowed\_origins". This array tells the native host which browser extensions are allowed to connect to it.  
   * **Add the Extension IDs you copied from Chrome and Edge** to this array.  
   * **For Firefox**, the field is typically allowed\_extensions and uses a different ID format. If you set a specific id in your manifest.json's browser\_specific\_settings.gecko.id (e.g., browser\_console@yourdomain.com), use that. Otherwise, use the temporary ID Firefox assigned.

   **Example com.example.browser\_console.json after adding IDs:**{  
       "name": "com.example.browser\_console",  
       "description": "Browser sidebar console host for native commands",  
       "path": "C:\\\\Projects\\\\MyBrowserConsoleProject\\\\backend\\\\run\_native\_host.bat",  
       "type": "stdio",  
       "allowed\_origins": \[  
         "chrome-extension://YOUR\_CHROME\_EXTENSION\_ID/",  \<-- PASTE CHROME ID HERE  
         "chrome-extension://YOUR\_EDGE\_EXTENSION\_ID/"     \<-- PASTE EDGE ID HERE  
       \],  
       "allowed\_extensions": \[                           \<-- NEW (OR ADD TO EXISTING) FOR FIREFOX  
         "browser\_console@yourdomain.com"                  \<-- PASTE FIREFOX ID HERE  
       \]  
     }

   * **Important:** Remember to keep the chrome-extension:// prefix and the trailing / for Chrome/Edge IDs. For Firefox, it's just the ID string.  
   * If you only plan to use one browser, you can remove the others. If you want to support both allowed\_origins and allowed\_extensions for different browsers, you might need both fields in your JSON, and the native host will check for either.  
3. **Save the com.example.browser\_console.json file.**

### **Step 4: Register the Native Host with Your System (Windows)**

This step tells your operating system where to find the native host.

1. **Open PowerShell as Administrator:**  
   * Search for "PowerShell" in your Windows Start Menu.  
   * Right-click on "Windows PowerShell" and select **"Run as administrator"**. This is important for registry access.  
2. **Navigate to the backend Folder:**  
   * In the PowerShell window, use the cd command to go to your backend directory.  
   * Example: cd C:\\YourPath\\Browser-Add-in-main\\backend  
3. **Run the Installer Script:**  
   * Execute the script by typing:  
     .\\install\_native\_host.ps1

   * If prompted about execution policy, type Y and press Enter.  
   * The script will print messages indicating successful registration for Chrome, Edge, and Firefox.

### **Step 5: Restart Your Browsers\!**

This is a crucial final step. Browsers often cache extension and native host information.

* **Completely close all open windows** of Chrome, Edge, and Firefox.  
* Re-open your desired browser(s).

## **✅ Testing Your New Browser Console\!**

1. **Open the Browser Console Sidebar:**  
   * In Chrome/Edge, click your extension's icon in the toolbar. It might open directly, or you might need to select "Open Browser Console" from a menu.  
   * In Firefox, you might need to right-click the toolbar, select "Customize Toolbar...", and drag the extension icon to a visible spot. Then click it.  
2. **Test Internal Commands:**  
   * Type help and press Enter.  
   * Type echo Hello World\! and press Enter.  
   * Type clear and press Enter.  
3. **Test Native Commands:**  
   * Type pwd and press Enter. You should see your current working directory.  
   * Type cd .. and press Enter. You should see "Directory changed to: ..."  
   * Type pwd again. It should now reflect the new directory\!  
   * Type dir (Windows) or ls \-l (Linux/macOS, if you set up a Linux/macOS native host) to see files in the current directory.

## **🐛 Troubleshooting Tips**

If things aren't working as expected, don't panic\! Here are some common issues and their solutions:

* **"Error: Native host disconnected: Access to the specified native messaging host is forbidden."**  
  * **Cause:** The browser's extension ID is not correctly listed in your com.example.browser\_console.json's allowed\_origins or allowed\_extensions array.  
  * **Fix:** Double-check the extension ID you copied from your browser (Step 2\) and ensure it's precisely added to the com.example.browser\_console.json file. Remember chrome-extension://ID/ for Chrome/Edge and just ID for Firefox (allowed\_extensions). Re-run the PowerShell script and restart browsers.  
* **"Error: Native host disconnected: Specified native messaging host not found."**  
  * **Cause:** The browser cannot find the com.example.browser\_console.json file registered in the system registry (Windows) or specific folders (macOS/Linux).  
  * **Fix:** Ensure you ran the install\_native\_host.ps1 script as Administrator and that it reported success. Verify the path in com.example.browser\_console.json points exactly to run\_native\_host.bat (using \\\\ for Windows paths in JSON). Restart browsers.  
* **... (awaiting native response) never goes away, and no output.**  
  * **Cause:** The native host process might be crashing immediately, or the run\_native\_host.bat script has an error.  
  * **Fix:** Check the native\_host\_debug.log file in your backend/ folder. It will contain Python errors if the script is crashing. Also, open a Command Prompt, navigate to backend/, and try running run\_native\_host.bat directly. Does it stay open? Does it show any errors?  
* **ReferenceError: sys is not defined in background.js console.**  
  * **Cause:** You have Python-specific syntax (file=sys.stderr) in your JavaScript console.log calls.  
  * **Fix:** Remove file=sys.stderr from all console.log and console.error calls in background.js. Reload the extension.  
* **cd command doesn't change directory for subsequent commands.**  
  * **Cause:** The current\_working\_directory variable in native\_host.py is not being updated persistently across commands.  
  * **Fix:** Ensure your native\_host.py is the absolute latest version from our conversation, especially the main() function logic for updating current\_working\_directory. Check the native\_host\_debug.log for the CWD \*\*UPDATED\*\* message.  
* **Extra "noisy" output (like conda\_hook.bat lines) before command output.**  
  * **Cause:** Your shell's startup scripts are running with each command executed via subprocess.run(shell=True).  
  * **Fix:** The native\_host.py has filtering logic in execute\_shell\_command. You might need to expand the ignore\_patterns list in that function to include other specific lines you want to filter out.

Enjoy your powerful new Browser Console\! If you encounter any issues, feel free to reach out. Happy browsing and commanding\!
